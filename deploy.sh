#!/bin/bash

# 获取当前时间和主机名
current_time=$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')
hostname=$(hostname)

# 颜色设置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
D='\033[0m'

# 尝试引入tte
export PATH="$HOME/.local/bin:$PATH"

# 定义加载动画函数
show_loading() {
    local pid=$1         # 接收后台命令的 PID
    local message=$2     # 提示信息
    local dots=('.    ' '..   ' '...  ' '.... ' '.....')
    local i=0

    # 隐藏光标
    tput civis

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r%s %s" "$message" "${dots[i++ % ${#dots[@]}]}"
        sleep 0.5
    done

    # 检查命令退出状态
    wait "$pid"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        printf "\r%s ${GREEN}SUCCESS${D}     \n" "$message"
    else
        printf "\r%s ${RED}FAILED${D}     \n" "$message"
        echo -e "${RED}Error:${D} $message failed with exit code $exit_code"
    fi

    # 恢复光标
    tput cnorm
}

# 定义后台运行函数
run_in_background() {
    local command=$1    # 接收要运行的命令
    local message=$2    # 提示信息
    
    eval "$command &>/dev/null &"  # 后台运行命令并隐藏输出
    show_loading $! "$message"     # 显示加载动画
}

# 定义多行命令后台运行函数
script_in_background() {
    local commands=$1    # 接收多行命令
    local message=$2     # 提示信息

    bash -c "$commands" &>/dev/null &  # 将多行命令作为一个整体运行，并隐藏输出
    show_loading $! "$message"         # 显示加载动画
}

echo -e "Now Checking ${BLUE}TerminalTextEffects${D}"

# # 检查 tte 是否安装
# if command -v tte &>/dev/null; then
#     echo -e "  ✔ ${BLUE}TTE ${GREEN}Installed${D}"
# else
#     echo -e "  ✘ ${BLUE}TTE ${D}is ${RED}not installed${D}"
#     echo -e "  ${YELLOW}→ Now performing installation task for ${BLUE}TTE${D}"

#     # 执行安装任务并使用 run_in_background
#     run_in_background "sudo apt update" "    PERFORMING APT UPDATE"
#     run_in_background "sudo apt install -y pip" "    INSTALLING PIP"
#     run_in_background "sudo apt install -y pipx" "    INSTALLING PIPX"
#     run_in_background "pipx install terminaltexteffects" "    INSTALLING TTE"
#     run_in_background "pipx ensurepath" "    CONFIGURING PATH"
#     source $HOME/.bashrc
#     export PATH="$HOME/.local/bin:$PATH"

#     if command -v tte &>/dev/null; then
#         echo -e "  ✔ ${GREEN}TTE Installation Completed Successfully!${D}"
#     else
#         echo -e "  ✘ ${RED}TTE Installation Failed!${D} Please reload your shell manually."
#     fi
# fi
# # 检查 gum 是否安装
echo -e "Now Checking ${BLUE}gum${D}"

if command -v gum &>/dev/null; then
    echo -e "  ✔ ${BLUE}gum ${GREEN}Installed${D}"
else
    echo -e "  ✘ ${BLUE}TTE ${D}is ${RED}not installed${D}"
    echo -e "  ${YELLOW}→ Now performing installation task for ${BLUE}gum${D}"

    # 执行安装任务并使用 script_in_background
    script_in_background '
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
        sudo apt update && sudo apt install gum
        ' "    RUNNING INSTALLATION SCRIPT"
    if command -v gum &>/dev/null; then
        echo -e "  ✔ ${GREEN}gum Installation Completed Successfully!${D}"
    else
        echo -e "  ✘ ${RED}gum Installation Failed!${D} Please check manually."
    fi
fi
echo -e "${YELLOW}Pre-installation environment ready!${D}" 
sleep 0.5
clear
# 显示欢迎信息并执行终端文本效果
echo -e "Greetings, ${BLUE}$username${D}" 
sleep 1
echo "We are now deploying Easytier to ${BLUE}$hostname${D}"
echo "The current time is $current_time"

install_easytier(){
    script_in_background '
    sudo wget -O /tmp/easytier.sh "https://raw.githubusercontent.com/EasyTier/EasyTier/main/script/install.sh"
    sudo chmod +x /tmp/easytier.sh
    sudo bash /tmp/easytier.sh install
    ' "RUNNING INSTALLATION SCRIPT"
}
config_easytier(){
    echo 'alias list-peers="/opt/easytier/easytier-cli peer"' >> "$HOME"/.bashrc
    source "$HOME"/.bashrc
    sudo systemctl stop easytier@default
    sudo mv /opt/easytier/config/default.conf /opt/easytier/config/"$NETWORKNAME.conf"
}
make_config_file(){
    sudo chmod 777 /opt/easytier/config/"$NETWORKNAME.conf"
    sudo echo "
instance_name = \"$INSTANCE_NAME\"
hostname = \"$hostname\"
dhcp = false
listeners = [
    \"tcp://0.0.0.0:11010\",
    \"udp://0.0.0.0:11010\",
    \"wg://0.0.0.0:11011\",
    \"ws://0.0.0.0:11011/\",
    \"wss://0.0.0.0:11012/\",
]
exit_nodes = []
rpc_portal = \"127.0.0.1:15888\"
ipv4 = \"$INTERNAL_IP\"
[network_identity]
network_name = \"$NETWORKNAME\"
network_secret = \"$NET_PASSWORD\"

[[peer]]
uri = \"$PEER_URI\"

[flags]
default_protocol = \"$DEFAULT_PROTOCAL\"
dev_name = \"\"
enable_encryption = true
enable_ipv6 = true
mtu = 1380
latency_first = false
enable_exit_node = false
no_tun = false
use_smoltcp = false
foreign_network_whitelist = \"*\"
disable_p2p = false
relay_all_peer_rpc = false
" > /opt/easytier/config/"$NETWORKNAME.conf"
}

# 确认是否继续
if gum confirm 'Does that sound good enough?'; then
    echo 'Proceeding with the deployment...'
    install_easytier
    NETWORKNAME=$(gum input --header "Desired networkname?" --placeholder "Enter your desired networkname here " --value "ayaka")
    config_easytier
    INSTANCE_NAME=$(gum input --header "Instance Name?" --placeholder "$hostname")
    INTERNAL_IP=$(gum input --header "Desired IP?" --placeholder "10.10.10.?")
    NET_PASSWORD=$(gum input --header "Network password?" --placeholder "Not gonna show you!" --password)
    DEFAULT_PROTOCAL=$(gum choose "tcp" "udp" "wg" "ws" "wss")
    PEER_URI=$(gum input --header "Peer URI" --placeholder "[protocal]://[IP]:[port]")
    make_config_file
    sudo systemctl start easytier@$NETWORKNAME
    sudo systemctl enable easytier@$NETWORKNAME
    echo  -e "${GREEN}DONE!${D}"
else
    echo "Sure, why not?" | tte print
    echo "See ya!" | tte print
    clear
fi

