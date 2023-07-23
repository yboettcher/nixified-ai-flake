{ buildPythonPackage, fetchPypi, lib, setuptools, transformers, diffusers, torch, pyparsing }:

buildPythonPackage rec {
  pname = "compel";
  version = "0.1.7";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-JP+PX0yENTNnfsAJ/hzgIA/cr/RhIWV1GEa1rYTdlnc=";
  };

  propagatedBuildInputs = [
    setuptools
    diffusers
    transformers
    torch
    pyparsing
  ];

#  # TODO FIXME
  doCheck = false;

  meta = {
    description = "A prompting enhancement library for transformers-type text embedding systems";
    homepage = "https://github.com/damian0815/compel";
  };
}
