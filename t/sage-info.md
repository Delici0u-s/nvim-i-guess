# to run

conda activate sage

Jupynium handles the rest

conda deactivate

- old commands
  - jupyter notebook --no-browser > sage_jupy.log 2>&1 &
  - in nvim <space> j n && <space> j s
  - sage -n jupyter
  - conda deactivate

# Setup

- requires `firefox`

```
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh

# restart shell, then:
conda init
#if that dont work try:
conda init zsh

conda create -n sage sage python=3.12
conda activate sage # if not activated by default
pip install notebook nbclassic jupyter-console # while in conda environment
sage --version # check

# dont auto to into (base)
conda config --set auto_activate_base false
```

- ~/.jupyter/jupyter_server_config.py  
  c.ServerApp.token = ''  
  c.ServerApp.password = ''
- Firefox:
  - mkdir \~/.mozilla/firefox
  - firefox --ProfileManager
    - create new profile named `Jupynium`
  - cat ~/.mozilla/firefox/profiles.ini
    - find profile
  - find the one with Jupynium as name and execute `firefox --profile ~/.mozilla/firefox/<Path>`
    - install dark mode extension

asd