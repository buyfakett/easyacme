#!/bin/bash
####################################################参数修改开始########################################################################

# 腾讯云
#export DP_Id='123xxx'
#export DP_Key='xxxxxxxxxxxxxxx'
#dns='dns_dp'

# 阿里云
export Ali_Key='xxxxxxxxxxxxxxx'
export Ali_Secret='xxxxxxxxxxxxxxx'
dns='dns_ali'

# Cloudflare
#export CF_Token='xxxxxxxxxxxxxxx'
#export CF_Account_ID='xxxxxxxxxxxxxxx'
#dns='dns_cf'

# 你的邮箱
email=xxx@xxx.com

####################################################参数修改结束########################################################################

# 脚本运行目录
workdir=/root/.acme.sh
# 域名
domain=$1

#颜色参数，让脚本更好看
Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 

# root权限
function root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}你现在不是root权限，请使用sudo命令或者联系网站管理员${Font}"
        exit 1
    fi
}

# 是否有acme.sh
function is_acme(){
    echo -e "${Green}开始判断是否有acme.sh${Font}"
    if [ ! -f "${workdir}/acme.sh" ];then
      echo -e "${Green}脚本不存在,开始下载并安装${Font}"
      git clone https://gitee.com/neilpang/acme.sh.git
      cd acme.sh
      ./acme.sh --install -m ${email}
      cd ..
      rm -rf acme.sh
      cd ${workdir}
    else
      echo -e "${Green}脚本存在${Font}"
      cd ${workdir}
    fi
}

# 域名是否存在
function is_domain(){
    echo -e "${Green}判断域名是否存在${Font}"

    if [ -d ${workdir}/${domain} ];then
      echo -e "${Green}域名存在，尝试续费${Font}"
      /bin/bash acme.sh --issue --dns ${dns} --force -r -d ${domain}
    else
      echo -e "${Green}域名不存在，新增域名${Font}"
      /bin/bash acme.sh --issue --dns ${dns} --force -d ${domain}
    fi
}

# 主方法
function main(){

    is_acme

    is_domain

    echo -e "${Red}ssl证书脚本执行结束${Font}"
}

if [ ! -z $1 ]; then
    if [ ! ${email}x == 'xxx@xxx.com'x ]
        main
    else
        echo -e "${Red}请修改脚本里的邮箱${Font}"
        exit 1
    fi
else
    echo -e "${Red}请传入域名${Font}"
    exit 1
fi