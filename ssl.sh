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

#脚本运行目录（默认不要动）
workdir=/root/.acme.sh
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

####################################################参数修改结束########################################################################

#颜色参数，让脚本更好看
Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 

#打印帮助文档
echo_help(){
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
    #使用rm -rf /root/.acme.sh/你的域名的整个文件夹 删除
    ——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
    ${Font}"
}

#等待5秒
sleep_5s(){
echo -e "${Red}5秒后继续执行脚本${Font}"
for i in {5..1}
do
  sleep 1
  echo -e ${Red}$i${Font}
done
}

#root权限
root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}你现在不是root权限，请使用sudo命令或者联系网站管理员${Font}"
        exit 1
    fi
}

#是否有acme.sh
is_acme(){
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
is_domain(){
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
cpssl(){
    echo -e "${Green}开始复制ssl证书${Font}"
    cp -R ${domain}/* ${nginxssl_dir}
    echo -e "${Green}复制ssl证书结束${Font}"
}

#全部执行（检测）
all(){
    root_need
    is_acme
    echo -e "${Red}当前域名${domain}${Font}"
    echo -e "${Green}域名脚本注册执行开始${Font}"
}

#只执行ssl证书
ssl_only(){
    echo -e "${Red}当前域名${domain}${Font}"
    echo -e "${Green}域名脚本注册执行开始${Font}"
}

#重载nginx
reload_nginx(){
    case "$1" in
        y)
            if [[ $nginx_stats == 1 ]];then
                docker exec -it ${docker_nginx_name} nginx -s reload
            elif [[ $nginx_stats == 0 ]];then
                nginx -s reload
            fi
        ;;
        *)
        echo ""
        ;;
        esac
}

#主方法
main(){
    echo_help
    sleep_5s
    if [[ $use_main == 1 ]];then
        all
    elif [[ $use_main == 0 ]];then
        ssl_only
    fi
    domain
    echo -e "${Green}域名脚本注册执行结束${Font}"
    echo -e "${Red}准备复制并重启nginx${Font}"
    sleep_5s
    cpssl
    reload_nginx
    echo -e "${Red}ssl证书脚本执行结束${Font}"
}
main