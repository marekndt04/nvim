# Personal Config Notice  
This is **my personal modified version** of the Lua configuration for [NvChad](https://github.com/NvChad/NvChad).  
It builds on the official NvChad setup and includes custom changes tailored to my preferences.

## Personal notes
- Be careful when installing `neovim`, as different package managers may provide different current stable versions. In my case, Ubuntu `apt` installed 0.6.x, while the recommended stable version available via `appimage` was 0.11.x.
- Many `neovim` functionalities and features require `npm`, install it right after the `neovim` installation.
```
        sudo apt update
        sudo apt install -y nodejs npm
        # and python if u missed it ;)
        sudo apt install -y python3-pip python3-venv
```
- Make sure you're using the latest version of node.js. In my case, an outdated version caused issues with pyright initialization—some JavaScript features were broken or outdated. Keep this in mind.
- The next important step is to install other useful packages, I did that using this command: `sudo apt install gcc ripgrep unzip xclip`
    - `gcc` – GNU C/C++ compiler  
    - `ripgrep` – Fast text searcher  
    - `unzip` – Extract `.zip` archives  
    - `xclip` – Clipboard access in terminal (This one is especially useful because it syncs the clipboard between Ctrl+C and yank operations.)
- The remaining configuration was based on the [ProgrammingRainbow](https://github.com/ProgrammingRainbow/NvChad-2.5?tab=readme-ov-file).

