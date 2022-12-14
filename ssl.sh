#!/bin/bash
####################################################参数修改开始########################################################################

#腾讯云
export DP_Id='123xxx'
export DP_Key='xxxxxxxxxxxxxxx'
dns='dns_dp'

#阿里云
#export Ali_Key='xxxxxxxxxxxxxxx'
#export Ali_Secret='xxxxxxxxxxxxxxx'
#dns='dns_ali'

#Cloudflare
#export CF_Token='xxxxxxxxxxxxxxx'
#export CF_Account_ID='xxxxxxxxxxxxxxx'
#dns='dns_cf'

#nginx的ssl目录
nginxssl_dir=/root/nginx/ssl
#你的邮箱
email=xxx.com
#你的域名
domain=xxx.com
#是否检查 1为检查 0为不检查
use_main=1
#设置nginx只运行在docker环境还是非docker环境 1为docker 0为非docker
nginx_stats=1
#docker中nginx的name或者id（用于reload）
docker_nginx_name=nginx
#脚本大师模式和新手模式（脚本设有等待时间看参数，大师模式1可以去掉等待时间）
shell_type=0
#检查版本（0是不检查；1是检测gitee；2是检测github）
inspect_script=1

####################################################参数修改结束########################################################################

#本地脚本版本号
shell_version=v1.0.2
#脚本运行目录（默认不要动）
workdir=/root/.acme.sh
#远程仓库作者
git_project_author_name=buyfakett
#远程仓库项目名
git_project_project_name=easyacme
#远程仓库名
git_project_name=${git_project_author_name}/${git_project_project_name}

#颜色参数，让脚本更好看
Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 

#打印帮助文档
function echo_help(){
    echo -e "${Green}
    ——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
    #此脚本只能用于阿里云的域名
    #在使用国内的服务器需先备案才能正常访问
    #可以定时任务执行这个脚本，但不会reload nginx
    #可以手动传值进行reload，如：
    #bash ssl-v1 xxx.com y
    #运行脚本前先编辑此脚本的参数
    #不需要的参数在前面加“#”注释
    #use_main参数可以控制是否检查权限，文件等问题
    #首次可能执行两次，并且删除/root/.acme.sh/你的域名的整个文件夹
    #使用rm -rf /root/.acme.sh/你的域名的整个文件夹删除
    #脚本不是很成熟，有bug请及时在github反馈哦~
    #或者发作者邮箱：buyfakett@vip.qq.com
    ——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
    ${Font}"
}

#等待5秒
function sleep_5s(){
    echo -e "${Red}5秒后继续执行脚本${Font}"
    for i in {5..1}
    do
      sleep 1
      echo -e ${Red}$i${Font}
    done
}

#root权限
function root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}你现在不是root权限，请使用sudo命令或者联系网站管理员${Font}"
        exit 1
    fi
}

#检查版本
function is_inspect_script(){
    yum install -y wget jq

    if [ $inspect_script == 1 ];then
        remote_version=$(wget -qO- -t1 -T2 "https://gitee.com/api/v5/repos/${git_project_name}/releases/latest" |  jq -r '.tag_name')
    elif [ $inspect_script == 2 ];then
        remote_version=$(wget -qO- -t1 -T2 "https://api.github.com/repos/${git_project_name}/releases/latest" |  jq -r '.tag_name')
    fi

    if [ ! "${remote_version}"x = "${shell_version}"x ];then
        if [ $inspect_script == 1 ];then
            wget -N "https://gitee.com/${git_project_name}/releases/download/${remote_version}/$0"
        elif [ $inspect_script == 2 ];then
            wget -N "https://github.com/${git_project_name}/releases/download/${remote_version}/$0"
        fi
    else
        echo -e "${Green}您现在的版本是最新版${Font}"
    fi
    echo -e "${Green}您已更新最新版本，请重新执行${Font}"
    exit 1
}

#是否有acme.sh
function is_acme(){
    echo -e "${Green}开始判断是否有acme.sh${Font}"
    if [ ! -f "${workdir}/acme.sh" ];then
      echo -e "${Green}脚本不存在,开始下载并安装${Font}"
      cd ${workdir}
      curl  https://get.acme.sh | sh
      /bin/sh -x /root/.acme.sh/acme.sh --register-account -m ${email} --server zerossl
    else
      echo -e "${Green}脚本存在${Font}"
      cd ${workdir}
    fi
}

#域名是否存在
function is_domain(){
    echo -e "${Green}判断域名是否存在${Font}"
    /bin/bash acme.sh --list |awk '{print $1}'|grep -x ${domain}

    if [ $? -eq 0 ];then
      echo -e "${Green}域名存在，尝试续费${Font}"
      /bin/bash acme.sh --issue --dns ${dns} --force -r -d ${domain}
    else
      echo -e "${Green}域名不存在，新增域名${Font}"
      /bin/bash acme.sh --issue --dns ${dns} --force -d ${domain}
    fi
}

#复制ssl证书
function cpssl(){
    echo -e "${Green}开始复制ssl证书${Font}"
    cp -R ${domain}/* ${nginxssl_dir}
    echo -e "${Green}复制ssl证书结束${Font}"
}

#全部执行（检测）
function all(){
    root_need
    is_acme
    echo -e "${Red}当前域名${domain}${Font}"
    echo -e "${Green}域名脚本注册执行开始${Font}"
}

#只执行ssl证书
function ssl_only(){
    echo -e "${Red}当前域名${domain}${Font}"
    echo -e "${Green}域名脚本注册执行开始${Font}"
}

#重载nginx
function reload_nginx(){
    [ "$1"x == "y"x ] && 
    if [[ $nginx_stats == 1 ]];then
        docker exec -it ${docker_nginx_name} nginx -s reload
    elif [[ $nginx_stats == 0 ]];then
        nginx -s reload
    fi || echo "0"
}

#主方法
function main(){
    if [ ! $inspect_script == 0 ];then
        echo -e "${Green}您已开始检查版本${Font}"
        is_inspect_script
    else
        echo -e "${Green}您已跳过检查版本${Font}"
    fi
    echo_help

    if [[ $shell_type == 0 ]];then
        sleep_5s
    fi

    #当前脚本位置
    echo "当前脚本位置：$(pwd)/$0，请确认"
    if [[ $shell_type == 0 ]];then
        sleep_5s
    fi

    if [[ $use_main == 1 ]];then
        all
    elif [[ $use_main == 0 ]];then
        ssl_only
    fi

    domain
    echo -e "${Green}域名脚本注册执行结束${Font}"
    echo -e "${Red}准备复制并重启nginx${Font}"
    
    if [[ $shell_type == 0 ]];then
        sleep_5s
    fi

    cpssl
    reload_nginx
    echo -e "${Red}ssl证书脚本执行结束${Font}"
}
main
