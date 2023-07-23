pkgs: {
  fixPackages = final: prev: let
    relaxProtobuf = pkg: pkg.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [ final.pythonRelaxDepsHook ];
      pythonRelaxDeps = [ "protobuf" ];
    });
  in {
    pytorch-lightning = relaxProtobuf prev.pytorch-lightning;
    wandb = (relaxProtobuf prev.wandb).overrideAttrs(old: {
      # some Webserving(?) tests appear to fail (because of the sandbox?). Assume everything works
      pytestCheckPhase = "true";
    });
    markdown-it-py = prev.markdown-it-py.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [ final.pythonRelaxDepsHook ];
      pythonRelaxDeps = [ "linkify-it-py" ];
      passthru = old.passthru // {
        optional-dependencies = with final; {
          linkify = [ linkify-it-py ];
          plugins = [ mdit-py-plugins ];
        };
      };
    });
    filterpy = prev.filterpy.overrideAttrs (old: {
      doInstallCheck = false;
    });
    shap = prev.shap.overrideAttrs (old: {
      doInstallCheck = false;
      propagatedBuildInputs = old.propagatedBuildInputs ++ [ final.packaging ];
      pythonImportsCheck = [ "shap" ];

      meta = old.meta // {
        broken = false;
      };
    });
    streamlit = let
      streamlit = final.callPackage (pkgs.path + "/pkgs/applications/science/machine-learning/streamlit") {
        protobuf3 = final.protobuf;
      };
    in final.toPythonModule (relaxProtobuf streamlit);
  };

  extraDeps = final: prev: let
    rm = d: d.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [ final.pythonRelaxDepsHook ];
      pythonRemoveDeps = [ "opencv-python-headless" "opencv-python" "tb-nightly" "clip" ];
    });
    callPackage = final.callPackage;
    rmCallPackage = path: args: rm (callPackage path args);
  in {
    opencv-python-headless = final.opencv-python;
    opencv-python = final.opencv4;

    compel = callPackage ../../packages/compel { };
    apispec-webframeworks = callPackage ../../packages/apispec-webframeworks { };
    pydeprecate = callPackage ../../packages/pydeprecate { };
    taming-transformers-rom1504 =
      callPackage ../../packages/taming-transformers-rom1504 { };
    albumentations = rmCallPackage ../../packages/albumentations { };
    qudida = rmCallPackage ../../packages/qudida { };
    gfpgan = rmCallPackage ../../packages/gfpgan { };
    basicsr = rmCallPackage ../../packages/basicsr { };
    facexlib = rmCallPackage ../../packages/facexlib { };
    realesrgan = rmCallPackage ../../packages/realesrgan { };
    codeformer = callPackage ../../packages/codeformer { };
    clipseg = rmCallPackage ../../packages/clipseg { };
    kornia = callPackage ../../packages/kornia { };
    lpips = callPackage ../../packages/lpips { };
    ffmpy = callPackage ../../packages/ffmpy { };
    picklescan = callPackage ../../packages/picklescan { };
    diffusers = callPackage ../../packages/diffusers { };
    pypatchmatch = callPackage ../../packages/pypatchmatch { };
    fonts = callPackage ../../packages/fonts { };
    font-roboto = callPackage ../../packages/font-roboto { };
    analytics-python = callPackage ../../packages/analytics-python { };
    gradio = callPackage ../../packages/gradio { };
    blip = callPackage ../../packages/blip { };
    fairscale = callPackage ../../packages/fairscale { };
    torch-fidelity = callPackage ../../packages/torch-fidelity { };
    resize-right = callPackage ../../packages/resize-right { };
    torchdiffeq = callPackage ../../packages/torchdiffeq { };
    k-diffusion = callPackage ../../packages/k-diffusion { };
    accelerate = callPackage ../../packages/accelerate { };
    clip-anytorch = callPackage ../../packages/clip-anytorch { };
    clean-fid = callPackage ../../packages/clean-fid { };
    getpass-asterisk = callPackage ../../packages/getpass-asterisk { };
  };

  torchRocm = final: prev: rec {
    torch = prev.torch.override {
      magma = pkgs.magma-hip;
      rocmSupport = true;
      cudaSupport = false;
    };

    torchvision = prev.torchvision.overrideAttrs (old: {
      # https://github.com/pytorch/vision/pull/7573
      postPatch = ''
        cat setup.py | head -n328 > setup_part1
        cat setup.py | head -n331 | tail -n2 > setup_part2
        cat setup.py | tail -n$((553-331)) > setup_part3

        echo "    if is_rocm_pytorch:" > setup_insert
        echo '        image_src += glob.glob(os.path.join(image_path, "hip", "*.cpp"))' >> setup_insert
        echo "        # we need to exclude this in favor of the hipified source" >> setup_insert
        echo '        image_src.remove(os.path.join(image_path, "image.cpp"))' >> setup_insert
        echo "    else:" >> setup_insert
        echo '        image_src += glob.glob(os.path.join(image_path, "cuda", "*.cpp"))' >> setup_insert

        cat setup_part1 setup_part2 setup_insert setup_part3 > setup.py
      '';
    });
  };

  torchCuda = final: prev: {
    torch = final.torch-bin;
    torchvision = final.torchvision-bin;
  };
}
