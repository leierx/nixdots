import argparse
import time

from jeepney import DBusAddress, MessageType, new_method_call
from jeepney.io.blocking import open_dbus_connection

# Notifications as fast as the session bus takes them, pipelined rather than one process each as notify-send is.
parser = argparse.ArgumentParser(prog="qs-flood")
parser.add_argument("count", type=int)
parser.add_argument("--urgency", type=int, default=1, choices=[0, 1, 2])
parser.add_argument("--apps", type=int, default=1, help="cycle through this many app names")
parser.add_argument("--summary", type=int, default=0, help="a summary this many characters long")
parser.add_argument("--body", type=int, default=0, help="a body this many characters long")
parser.add_argument("--icon", default="")
parser.add_argument("--app", default="Flood")
parser.add_argument("--rate", type=float, default=0, help="no more than this many a second")
parser.add_argument("--updates", type=int, default=0, help="then this many updates by id of the last one")
parser.add_argument("--close", action="store_true", help="then close the last one, in the same breath as its last update")
args = parser.parse_args()

bus = open_dbus_connection(bus="SESSION")
server = DBusAddress("/org/freedesktop/Notifications", bus_name="org.freedesktop.Notifications", interface="org.freedesktop.Notifications")
window = 256
pending = 0
errors = 0
start = time.monotonic()


def settle(limit):
    global pending, errors
    while pending > limit:
        reply = bus.receive(timeout=30)
        if reply.header.message_type == MessageType.error:
            errors += 1
        if reply.header.message_type in (MessageType.method_return, MessageType.error):
            pending -= 1


for n in range(args.count):
    app = f"{args.app}{n % args.apps}" if args.apps > 1 else args.app
    summary = "S" * args.summary if args.summary else f"{app} {n}"
    body = ("lorem ipsum " * (args.body // 12 + 1))[: args.body] if args.body else f"number {n}"
    hints = {"urgency": ("y", args.urgency)}
    bus.send(new_method_call(server, "Notify", "susssasa{sv}i", (app, 0, args.icon, summary, body, [], hints, -1)))
    pending += 1
    settle(window)
    if args.rate:
        time.sleep(1 / args.rate)
settle(0)

if args.updates or args.close:
    # The id of the last, then its updates and close sent back to back, as a client replacing and closing at once does.
    reply = bus.send_and_get_reply(new_method_call(server, "Notify", "susssasa{sv}i", (args.app, 0, args.icon, "last", "first", [], {"urgency": ("y", args.urgency)}, -1)))
    last = reply.body[0]
    for n in range(args.updates):
        bus.send(new_method_call(server, "Notify", "susssasa{sv}i", (args.app, last, args.icon, "last", f"update {n}", [], {"urgency": ("y", args.urgency)}, -1)))
        pending += 1
    if args.close:
        bus.send(new_method_call(server, "CloseNotification", "u", (last,)))
        pending += 1
    settle(0)
took = time.monotonic() - start
print(f"{args.count} sent in {took:.1f} s, {args.count / took:.0f} a second, {errors} refused")
