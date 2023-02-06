<#Для выполнения ДЗ была создана VM с LVM.
При загрузке доавил rd.break (опция rd.break загрузки сообщает, 
что последовательность загрузки должна быть остановлена, пока система все еще использует initramfs, 
но реальная корневая файловая система уже смонтирована в /sysroot) в конец строки, начинающейся с linux16. 
Система загрузилась в аварийном режиме (emergency mode) #>
[switch_root]:/#

#Далее монтирую ФС в режиме чтение/запись
mount -o remount,rw /sysroot

# Запустим новую оболочку таким образом, чтобы для этой оболочки /sysroot каталог отображался как /
chroot /sysroot

#Сбросим пароль администратора
passwd root
touch /.autorelabel 

#Перезагружаемся и входим в систему с новым паролем
C:\Users\Dmitry.Kadochnikov>ssh dima@192.168.56.1
dima@192.168.56.1's password:

# Посмотрим информацию по VG
[root@srv1 dima]# vgs
  VG     #PV #LV #SN Attr   VSize  VFree
  centos   1   2   0 wz--n- <9.00g      0
  vg1      3   1   0 wz--n- <2.99g 612.00m

# Здесь нам нужно VG Centos - переименуем его
[root@srv1 dima]# vgrename centos OtusRoot
  Volume group "centos" successfully renamed to "OtusRoot"

# Далее правим информацию для загрузки с новым именем - /etc/fstab, /etc/default/grub, /boot/grub2/grub.cfg
vi /etc/fstab
/dev/mapper/OtusRoot-root /                       xfs     defaults        0 0
UUID=0532efe7-17f4-4af0-8e5c-e87015c798df /boot                   xfs     defaults        0 0
/dev/mapper/OtusRoot-swap swap                    swap    defaults        0 0

vi  /etc/default/grub
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto spectre_v2=retpoline rd.lvm.lv=OtusRoot/root rd.lvm.lv=OtusRoot/swap rhgb quiet"
GRUB_DISABLE_RECOVERY="true"

vi /boot/grub2/grub.cfg
#Исправленные строки ниже
linux16 /vmlinuz-3.10.0-1160.el7.x86_64 root=/dev/mapper/OtusRoot-root ro crashkernel=auto spectre_v2=retpoline rd.lvm.lv=OtusRoot/root rd.lvm.lv=OtusRoot/swap rhgb quiet LANG=en_US.UTF-8
linux16 /vmlinuz-0-rescue-7596680b4d6fd34993a49f7f8d09c2ec root=/dev/mapper/OtusRoot-root ro crashkernel=auto spectre_v2=retpoline rd.lvm.lv=OtusRoot/root rd.lvm.lv=OtusRoot/swap rhgb quiet

#Пересоздаем initrd image, чтобы он знал новое название Volume Group
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
#Тут огромный вывод не прикладывал

#Перезагружаемся:
[root@srv1 dima]# shutdown -r 0
Shutdown scheduled for Mon 2023-02-06 08:00:02 EST, use 'shutdown -c' to cancel.
[root@srv1 dima]# Connection to 192.168.56.1 closed by remote host.
Connection to 192.168.56.1 closed.

#Проверяем после перезагрузки
C:\Users\Dmitry.Kadochnikov>ssh dima@192.168.56.1
dima@192.168.56.1's password:
Last login: Mon Feb  6 07:40:54 2023 from gateway
[dima@srv1 ~]$ sudo su
[sudo] password for dima:
[root@srv1 dima]# vgs
  VG       #PV #LV #SN Attr   VSize  VFree
  OtusRoot   1   2   0 wz--n- <9.00g      0
  vg1        3   1   0 wz--n- <2.99g 612.00m

#Добавим свой модуль 
[root@srv1 dima]# cd /usr/lib/dracut/modules.d/
[root@srv1 modules.d]# ls
00bash               50plymouth            90multipath   95nbd           98selinux
00systemd-bootchart  80cms                 90qemu        95nfs           98syslog
03modsign            90bcache              90qemu-net    95resume        98systemd
03rescue             90btrfs               91crypt-gpg   95rootfs-block  98usrmount
04watchdog           90crypt               91crypt-loop  95ssh-client    99base
05busybox            90dm                  95cifs        95terminfo      99fs-lib
05nss-softokn        90dmraid              95dasd        95udev-rules    99img-lib
10i18n               90dmsquash-live       95dasd_mod    95virtfs        99kdumpbase
30convertfs          90dmsquash-live-ntfs  95debug       95zfcp          99microcode_ctl-fw_dir_override
40network            90kernel-modules      95fcoe        95znet          99shutdown
45ifcfg              90livenet             95fcoe-uefi   97biosdevname   99uefi-lib
45url-lib            90lvm                 95fstab-sys   98ecryptfs
50drm                90mdraid              95iscsi       98pollcdrom

[root@srv1 modules.d]# mkdir /usr/lib/dracut/modules.d/01test
[root@srv1 modules.d]# cd 01test/
[root@srv1 01test]# touch module-setup.sh
[root@srv1 01test]# touch test.sh
[root@srv1 01test]# vi module-setup.sh[root@srv1 01test]
[root@srv1 01test]# vi test.sh
[root@srv1 01test]# cat module-setup.sh
#!/bin/bash

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_hook cleanup 00 "${moddir}/test.sh"
}
[root@srv1 01test]# cat test.sh
#!/bin/bash

exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
cat <<'msgend'
Hello! You are in dracut module!
 ___________________
< I'm dracut module >
 -------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
msgend
sleep 10
echo " continuing...."
[root@srv1 01test]#

#Пересобираем образ initrd
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
#Огромный вывод - не прикладывал

#Проверим, загрузился ли наш образ в ядро
[root@srv1 01test]# lsinitrd -m /boot/initramfs-$(uname -r).img | grep test
test

<#Отредактируем /boot/grub2/grub.cfg
Удалим rghb и quiet из linux16 /vmlinuz-3.10.0-1160.el7.x86_64 root=/dev/mapper/OtusRoot-root ro crashkernel=auto spectre_v2=retpoline rd.lvm.lv=OtusRoot/root rd.lvm.lv=OtusRoot/swap rhgb quiet LANG=en_US.UTF-8
и из 
linux16 /vmlinuz-0-rescue-7596680b4d6fd34993a49f7f8d09c2ec root=/dev/mapper/OtusRoot-root ro crashkernel=auto spectre_v2=retpoline rd.lvm.lv=OtusRoot/root rd.lvm.lv=OtusRoot/swap rhgb quiet
#>
#Перезагружаемся
Скрин с результатом приложил картинкой в данную ветку - "Результат.jpg"
