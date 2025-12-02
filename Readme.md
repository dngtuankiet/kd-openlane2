<p align="center">
    <a href="https://github.com/librelane/librelane">
        <img src="./docs/_static/openlane2_banner.svg" style="width: 80%;overflow: visible" alt="Banner explaining that development has moved over to github.com/librelane/librelane"/>
    </a>
</p>

If you're looking to tapeout an OpenLane 2/LibreLane-based design with
ChipFoundry, an appropriate version of OpenLane 2/LibreLane will be
automatically pulled by  your target template:

* Caravel User Project: https://github.com/chipfoundry/caravel_user_project
* OpenFrame User Project: https://github.com/chipfoundry/openframe_user_project

---

<h1 align="center">OpenLane</h1>
<p align="center">
    <a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License: Apache 2.0"/></a>
    <a href="https://www.python.org"><img src="https://img.shields.io/badge/Python-3.8-3776AB.svg?style=flat&logo=python&logoColor=white" alt="Python 3.8 or higher" /></a>
    <a href="https://github.com/psf/black"><img src="https://img.shields.io/badge/code%20style-black-000000.svg" alt="Code Style: black"/></a>
    <a href="https://mypy-lang.org/"><img src="https://www.mypy-lang.org/static/mypy_badge.svg" alt="Checked with mypy"/></a>
    <a href="https://nixos.org/"><img src="https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a" alt="Built with Nix"/></a>
</p>

OpenLane is an ASIC infrastructure library based on several components including
OpenROAD, Yosys, Magic, Netgen, CVC, KLayout and a number of custom scripts for
design exploration and optimization.

A reference flow, "Classic", performs all ASIC implementation steps from RTL all
the way down to GDSII.

You can find the documentation
[here](https://openlane2.readthedocs.io/en/latest/getting_started/) to get
started.

## Try it out

You can try OpenLane right in your browser, free-of-charge, using Google
Colaboratory by following
[**this link**](https://colab.research.google.com/github/efabless/openlane2/blob/main/notebook.ipynb).

## Installation

You'll need the following:

* Python **3.8** or higher with PIP, Venv and Tkinter

### Nix (Recommended)

Works for macOS and Linux (x86-64 and aarch64). Recommended, as it is more
integrated with your filesystem and overall has less upload and download deltas.

See
[Nix-based installation](https://openlane2.readthedocs.io/en/latest/getting_started/common/nix_installation/index.html)
in the docs for more info.

### Docker

Works for Windows, macOS and Linux (x86-64 and aarch64).

See
[Docker-based installation](https://openlane2.readthedocs.io/en/latest/getting_started/common/docker_installation/index.html)
in the docs for more info.

Do note you'll need to add `--dockerized` right after `openlane` in most CLI
invocations.

### Python-only Installation (Advanced, Not Recommended)

**You'll need to bring your own compiled utilities**, but otherwise, simply
install OpenLane as follows:

```sh
python3 -m pip install --upgrade openlane
```

Python-only installations are presently unsupported and entirely at your own
risk.

## Usage

In the root folder of the repository, you may invoke:

```sh
python3 -m openlane --pdk-root <path/to/pdk> </path/to/config.json>
```

To start with, you can try:

```sh
python3 -m openlane --pdk-root $HOME/.volare ./designs/spm/config.json
```

## Publication

If you use OpenLane in your research, please cite the following paper.

* M. Shalan and T. Edwards, “Building OpenLANE: A 130nm OpenROAD-based
  Tapeout-Proven Flow: Invited Paper,” *2020 IEEE/ACM International Conference
  On Computer Aided Design (ICCAD)*, San Diego, CA, USA, 2020, pp. 1-6.
  [Paper](https://ieeexplore.ieee.org/document/9256623)

```bibtex
@INPROCEEDINGS{9256623,
  author={Shalan, Mohamed and Edwards, Tim},
  booktitle={2020 IEEE/ACM International Conference On Computer Aided Design (ICCAD)}, 
  title={Building OpenLANE: A 130nm OpenROAD-based Tapeout- Proven Flow : Invited Paper}, 
  year={2020},
  volume={},
  number={},
  pages={1-6},
  doi={}}
```

## License and Information

[The Apache License, version 2.0](https://www.apache.org/licenses/LICENSE-2.0.txt).

Docker images distributed by Efabless Corporation under the same license.

Binaries bundled with OpenLane either via Cachix or Docker are distributed by
Efabless Corporation and may fall under stricter open source licenses.
