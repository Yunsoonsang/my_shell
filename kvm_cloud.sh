#!/bin/bash
volume="" # 이미지 볼륨
name="" # 인스턴스 이름이자 hostname
flavor="" # 인스턴스 스펙 = cpu, ram
cpu=""
ram=""
com=""
vmcount="" # 생성할 인스턴스의 개수
com1_usage=""
com2_usage=""

# 메뉴1 - 가상 인스턴스 생성하기
function create_instance {
        echo -e "\n\t가상 인스턴스 생성하기 메뉴 실행"
        # 인스턴스 이미지 볼륨 선택하기
        menu_volume
        # 인스턴스 이름 입력받기 - hostname으로도 사용
        menu_name
        # flavor 선택메뉴
        menu_flavor
        # 생성할 인스턴스의 개수 입력받기
        menu_vmcount
        #echo -e "\t\t현재까지 입력된 데이터 출력"
        #echo -e "\tvolume = $volume"
        #echo -e "\tname = $name"
        #echo -e "\tflavor = $flavor"
        #echo -e "\tvmcount = $vmcount"
        echo -e "\t인스턴스를 생성할 노드를 결정하는 중 입니다. 잠시 기다려 주세요..."
        com1_usage=$(ssh compute1 'cpu.sh')
        com2_usage=$(ssh compute2 'cpu.sh')
        echo -e "\tcom1:$com1_usage, com2:$com2_usage"
        if [ $com2_usage -eq $com1_usage ]
        then
                # 두 노드의 cpu사용량이 같으므로 default로 compute1에 설치
                com="compute1"
                create compute1
        elif [ $com2_usage -gt $com1_usage ]
        then
                # compute1에 인스턴스 생성
                com="compute1"
                create compute1
        else
                # compute2에 인스턴스 생성
                com="compute2"
                create compute2
        fi
}
# 메뉴2 - 가상 인스턴스 목록확인하기
function show_instance {
        echo -e "<< compute1 >>"
        ssh compute1 'virsh list --all'
        echo -e "<< compute2 >>"
        ssh compute2 'virsh list --all'
}
# 메뉴3 - 가상 인스턴스 삭제하기
function delete_instance {
        clear
        echo -e "\t\t가상 인스턴스 삭제 메뉴 실행"
        show_instance
        echo -en "\t목록을 보시고 어느 compute에 있는지 입력하세요. : "
        read com
        echo -en "\t인스턴스 이름을 입력하세요. : "
        read name

        ssh $com "virsh destroy $name"
        sleep 3
        ssh $com "virsh undefine $name --remove-all-storage"
        echo -e "\t\t인스턴스 삭제 완료"
        delete_database $name
}
# 메뉴판
function menu {
        clear
        echo
        echo -e "\t\tKAKAO Cloud Engineer KVM Project\n"
        echo -e "\t1. 가상 인스턴스 생성하기"
        echo -e "\t2. 가상 인스턴스 목록 확인하기"
        echo -e "\t3. 가상 인스턴스 삭제하기"
        echo -e "\t0. 종료하기"
        echo -en "\t\t메뉴번호를 선택하세요! : "
        read -n 1 option
        echo
}
# image vloume 선택 메뉴판
function menu_volume {
        while [ 1 ]
        do
                clear
                echo
                echo -e "\t사용 가능한 클라우드 이미지 볼륨 목록 출력\n"
                echo -e "\t1. CentOS-7"
                echo -e "\t2. CentOS-8"
                echo -en "\t\t메뉴번호를 선택하세요! : "
                read -n 1 option
                echo
                case $option in
                1)
                        volume="CentOS-7.qcow2"
                        break;;
                2)
                        volume="CentOS-8.qcow2"
                        break;;
                *)
                        clear
                        echo -e "\t존재하지 않는 메뉴 번호를 선택했습니다.";;
                esac
                echo -en "\n\n\t\t\t아무 키나 입력하시고 메뉴를 선택해주세요!"
                read -n 1 line
        done
}
# 인스턴스 이름 입력받기
function menu_name {
        while [ 1 ]
        do
                clear
                # 인스턴스 이름 입력받기 - hostname으로도 사용
                echo -e "\t인스턴스의 이름을 입력하세요."
                echo -e "\t알파벳 소문자와 숫자로 최소 5글자 ~ 최대 10글자로 구성하세요. 첫 시작은 반드시 문자여야 합니다."
                echo -en "\t 인스턴스 이름 : "
                read name
                name=$(echo $name | gawk '/^[a-z]{1}[a-z0-9]{4,9}$/{print $0}')
                if [ -z $name ]
                then
                        clear
                        echo -e "\n\t잘못된 형식입니다. 패턴:[a-z]{1}[a-z0-9]{4,9}"
                        echo -en "\n\n\t\t\t아무 키나 입력하시고 메뉴를 선택해주세요!"
                        read -n 1 line
                else
                        break
                fi
        done
}
# flavor 메뉴판
function menu_flavor {
        while [ 1 ]
        do
                clear
                echo
                echo -e "\t인스턴스에 적용할 수 있는 flavor 목록\n"
                echo -e "\t1. m1.small : cpu 1, ram 1024"
                echo -e "\t2. m1.medium : cpu 2, ram 2048"
                echo -e "\t3. m1.large : cpu4, ram 4096"
                echo -en "\t\t메뉴번호를 선택하세요! : "
                read -n 1 option
                echo
                case $option in
                1)
                        flavor="m1.small"
                        cpu=1
                        ram=1024
                        break;;
                2)
                        flavor="m1.medium"
                        cpu=2
                        ram=2048
                        break;;
                3)
                        clear
                        echo -e "\t죄송합니다. m1.large는 현재 지원하지 않고 있습니다."
                        echo -e "\t다른 flavor를 선택해야 합니다. 죄송합니다...";;
                *)
                        clear
                        echo -e "\t존재하지 않는 메뉴 번호를 선택했습니다.";;
                esac
                echo -en "\n\n\t\t\t아무 키나 입력하시고 메뉴를 선택해주세요!"
                read -n 1 line
        done
}
function menu_vmcount {
        while [ 1 ]
        do
                clear
                echo
                echo -en "\t생성할 인스턴스의 개수를 입력하세요(최대 2개) [Enter] : "
                read vmcount

                vmcount=$(echo $vmcount | gawk '/^[1-2]{1}$/{print $0}')
                if [ -z $vmcount ]
                then
                        clear
                        echo -e "\t최소 1개, 최대 2개까지만 생성가능합니다. 그 이상은 힘듭니다. 죄송합니다..."
                echo -en "\n\n\t\t\t아무 키나 입력하시고 메뉴를 선택해주세요!"
                read -n 1 line
                else
                        break
                fi
        done
}
function create {
        if [ $1 = "compute1" ]
        then
                echo -e "\tcompute1에 생성"
                if [ $vmcount -eq 1 ]
                then
                        echo -e "\t\t$com에 인스턴스 1개 생성 시작!!!"
                        # 현재는 매우 간단하게 할 수 있도록 구현 더 추가해야함
                        ssh compute1 "cp /shared/${volume} /shared/${name}.qcow2"
                        ssh compute1 "virt-customize -a /shared/$name.qcow2 --root-password password:test123 --hostname $name --run-command 'useradd centos' --run-command 'mkdir /home/centos/.ssh' --run-command 'chmod 700 /home/centos/.ssh' --run-command 'chown centos:centos /home/centos/.ssh' --upload /shared/authorized_keys:/home/centos/.ssh/authorized_keys --upload /net/ifcfg-eth1:/etc/sysconfig/network-scripts/ifcfg-eth1 --selinux-relabel"
                        ssh compute1 "virt-install --name ${name} --vcpus ${cpu} --ram ${ram} --disk /shared/$name.qcow2 --import --network=bridge:vswitch01,model=virtio,virtualport_type=openvswitch --network=bridge:vswitch02,model=virtio,virtualport_type=openvswitch --noautoconsole"
                        sleep 3
                        # 생성완료를 판단하기 위해 ip생성을 기다리자 근데 지금은 추가 X
                        echo -e "\t\t$com에 인스턴스 1개 생성 완료!!!"
                        # 데이터베이스 업데이트 추가
                        upload_database $name $flavor $volume $com
                else
                        for((i=1; i<=$vmcount; i++))
                        do
                                echo -e "\t\t$com에 인스턴스 $i번째 생성 시작!!!"
                                ssh compute1 "cp /shared/$volume /shared/$name-$i.qcow2"
                                ssh compute1 "virt-customize -a /shared/$name-$i.qcow2 --root-password password:test123 --hostname $name-$i --run-command 'useradd centos' --run-command 'mkdir /home/centos/.ssh' --run-command 'chmod 700 /home/centos/.ssh' --run-command 'chown centos:centos /home/centos/.ssh' --upload /shared/authorized_keys:/home/centos/.ssh/authorized_keys --upload /net/ifcfg-eth1:/etc/sysconfig/network-scripts/ifcfg-eth1 --selinux-relabel"
                                ssh compute1 "virt-install --name ${name}-${i} --vcpus ${cpu} --ram ${ram} --disk /shared/$name-$i.qcow2 --import --network=bridge:vswitch01,model=virtio,virtualport_type=openvswitch --network=bridge:vswitch02,model=virtio,virtualport_type=openvswitch --noautoconsole"
                                sleep 60
                                echo -e "\t\t$com에 인스턴스 $i번째 생성 완료!!!"
                                # 데이터베이스 업데이트 추가
                                upload_database $name-$i $flavor $volume $com
                        done
                fi
        else
                echo -e "\tcompute2에 생성"
                if [ $vmcount -eq 1 ]
                then
                        echo -e "\t\t$com에 인스턴스 1개 생성 시작!!!"
                        # 현재는 매우 간단하게 할 수 있도록 구현 더 추가해야함
                        ssh compute2 "cp /shared/$volume /shared/$name.qcow2"
                        ssh compute2 "virt-customize -a /shared/$name.qcow2 --root-password password:test123 --hostname $name --run-command 'useradd centos' --run-command 'mkdir /home/centos/.ssh' --run-command 'chmod 700 /home/centos/.ssh' --run-command 'chown centos:centos /home/centos/.ssh' --upload /shared/authorized_keys:/home/centos/.ssh/authorized_keys --upload /net/ifcfg-eth1:/etc/sysconfig/network-scripts/ifcfg-eth1 --selinux-relabel"
                        ssh compute2 "virt-install --name ${name} --vcpus ${cpu} --ram ${ram} --disk /shared/$name.qcow2 --import --network=bridge:vswitch01,model=virtio,virtualport_type=openvswitch --network=bridge:vswitch02,model=virtio,virtualport_type=openvswitch --noautoconsole"
                        sleep 2
                        echo -e "\t\t$com에 인스턴스 1개 생성 완료!!!"
                        # 데이터베이스 업데이트 추가
                        upload_database $name $flavor $volume $com
                else
                        for((i=1; i<=$vmcount; i++))
                        do
                                echo -e "\t\t$com에 인스턴스 $i번째 생성 시작!!!"
                                ssh compute2 "cp /shared$volume /shared/$name-$i.qcow2"
                                ssh compute2 "virt-customize -a /shared/$name-$i.qcow2 --root-password password:test123 --hostname $name-$i --run-command 'useradd centos' --run-command 'mkdir /home/centos/.ssh' --run-command 'chmod 700 /home/centos/.ssh' --run-command 'chown centos:centos /home/centos/.ssh' --upload /shared/authorized_keys:/home/centos/.ssh/authorized_keys --upload /net/ifcfg-eth1:/etc/sysconfig/network-scripts/ifcfg-eth1 --selinux-relabel"
                                ssh compute2 "virt-install --name ${name}-${i} --vcpus ${cpu} --ram ${ram} --disk /shared/$name-$i.qcow2 --import --network=bridge:vswitch01,model=virtio,virtualport_type=openvswitch --network=bridge:vswitch02,model=virtio,virtualport_type=openvswitch --noautoconsole"
                                sleep 60
                                echo -e "\t\t$com에 인스턴스 $i번째 생성 완료!!!"
                                # 데이터베이스 업데이트 추가
                                upload_database $name-$i $flavor $volume $com
                        done

                fi
        fi
        echo -en "\n\n\t\t\t아무 키나 입력하시면 처음으로 돌아갑니다! "
        read -n 1 line
}
function upload_database {
        echo -e "\t데이터베이스 업데이트 진행"
        echo -e "\t저장할 데이터 name=$1, flavor=$2, os=$3, node=$4"
        mysql rapadb -u rapa -prapa << EOF
insert into instance_info(name, flavor, os, node) values('$1', '$2', '$3', '$4');
EOF
        echo -e "\t데이터베이스 업데이트 완료"
}
function delete_database {
        echo -e "\t데이터베이스 데이터 삭제 진행"
        echo -e "\t삭제할 인스턴스 이름 : $1"
        mysql rapadb -u rapa -prapa << EOF
delete from instance_info where name = '$1';
EOF
}
# main
while [ 1 ]
do
        menu
        case $option in
        0)
                echo -e "\t2초 뒤 프로그램을 종료합니다!"
                break;;
        1)
                create_instance;;
        2)
                show_instance;;
        3)
                delete_instance;;
        *)
                clear
                echo -e "\t존재하지 않는 메뉴 번호를 선택했습니다.  다시 메뉴를 선택해주세요.";;
        esac
        echo -en "\n\n\t\t\t아무 키나 입력하시면 다시 진행됩니다."
        read -n 1 line
done
sleep 2
clear
