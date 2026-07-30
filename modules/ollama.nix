{
  modules.nixos.ollama =
    { pkgs, ... }:
    {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-rocm;
        host = "127.0.0.1";
        port = 11434;

        # Treat gfx1031 (6700 XT) as gfx1030 for ROCm
        rocmOverrideGfx = "10.3.0";

        # Preload once so first prompt isn't cold. Only one lives in VRAM at a time.
        loadModels = [
          "gemma4:e4b"
          "gemma4:e2b"
          "gemma4:12b"
        ];

        environmentVariables = {
          # Single job at a time — matches your hardware reality
          OLLAMA_MAX_LOADED_MODELS = "1";
          OLLAMA_NUM_PARALLEL = "1";
          # Keep the loaded model resident between agent turns (avoid re-load churn)
          OLLAMA_KEEP_ALIVE = "60m";
          # VRAM-savers — meaningful on 12 GB
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
          # Belt-and-suspenders for the gfx1031 → gfx1030 override
          HSA_OVERRIDE_GFX_VERSION = "10.3.0";
          HIP_VISIBLE_DEVICES = "0";
        };
      };
    };
}
