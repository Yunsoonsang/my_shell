# 카카오 클라우드 엔지니어 4기 - KVM 프로젝트

## 사용된 노드
- **Control:** `kvm_cloud.sh` (서비스 실행), Zabbix-Server, MariaDB (Master)
- **Backup:** MariaDB (Slave)
- **Compute1, 2:** KVM, OVS & GRE Tunering Overlay Network 구성
- **Storage:** RAID 1 구성, NFS Server

## 이중화(High Availability) 구성
### Storage (NFS, RAID 1)
- 파일 스토리지 방식으로 Compute가 생성할 VM의 volume을 제공합니다.
- RAID 1을 통해 스토리지의 이중화를 구현했습니다.

### Backup (DB Replication)
- Control과 Master-Slave DB Replication을 구성하여 DB에 대한 이중화를 구현했습니다.

## 쉘 코드
- [kvm_cloud.sh](./kvm_cloud.sh): KVM 클라우드 서비스 실행을 위한 쉘 코드
- [Control Shell Code](https://github.com/Yunsoonsang/my_shell/blob/main/kvm_cloud.sh)

## 프로젝트 프레젠테이션
- [PDF](KAKAO Cloud Enginner 4 - KVM Service.pdf)
