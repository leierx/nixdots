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
took = time.monotonic() - start
print(f"{args.count} sent in {took:.1f} s, {args.count / took:.0f} a second, {errors} refused")
