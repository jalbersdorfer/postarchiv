# The Scanner Pi

I use a **Fujitsu fi-6140 Scanner** connected to a **RaspberryPi Zero 2-W** which runs **ArchLinux ARM**.

## Installation of ArchLinux ARM

pass

## Installation of the Requirements

```shell
# history
    1  pacman-key --init
    2  pacman-key --populate archlinuxarm
    3  pacman -Syu
    4  cp boot/wpa_supplicant.conf etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    5  exit
    6  systemctl start wpa_supplicant
    7  systemctl status wpa_supplicant
    8  ip addr
    9  ip addr
   10  ifup wlan0
   11  systemctl status wpa_supplicant
   12  systemctl enable wpa_supplicant
   13  vim /etc/wpa_supplicant/wpa_supplicant-wlan0.conf 
   14  vi /etc/wpa_supplicant/wpa_supplicant-wlan0.conf 
   15  ls -lha /etc/wpa_supplicant/
   16  vi /etc/systemd/network/wlan0.network 
   17  vi /etc/systemd/network/wlan0.network 
   18  reboot
   19  ip addr
   20  ifconfig wlan0 up
   21  ip addr
   22  systemctl status sshd
   23  netstat
   24  netstat -tulpen
   25  systemctl status systemd-networkd
   26  ip addr
   27  systemctl restart systemctl-networkd
   28  systemctl restart systemd-networkd
   29  systemctl status systemd-networkd
   30  ip addr
   31  cat /etc/systemd/network/wlan0.network 
   32  vi /etc/systemd/network/wlan0.network 
   33  cat /etc/systemd/network/wlan0.network 
   34  systemctl restart systemd-networkd
   35  systemctl status systemd-networkd
   36  ip addr
   37  systemctl status wpa_supplicant
   38  netctl
   39  networkctl 
   40  networkctl --help
   41  networkctl up wlan0
   42  ip addr
   43  networkctl reconfigure wlan0
   44  ip addr
   45  networkctl 
   46  vi /etc/wpa_supplicant/wpa_supplicant-wlan0.conf 
   47  mv /etc/wpa_supplicant/wpa_supplicant-wlan0.conf /etc/wpa_supplicant/wpa_supplicant.conf
   48  systemctl restart wpa_supplicant
   49  systemctl status wpa_supplicant
   50  networkctl 
   51  networkctl reconfigure wlan0
   52  netctl
   53  netctl list
   54  netcap 
   55  netctl-auto 
   56  netctl-auto list
   57  ip addr
   58  wpa_cli 
   59  systemctl stop wpa_supplicant
   60  wpa_cli 
   61  systemctl start wpa_supplicant
   62  wpa_cli 
   63  wpa_cli --help
   64  wpa_cli --help | more
   65  systemctl status network-manager
   66  systemctl list-units
   67  systemctl list-units | grep network
   68  systemctl restart network
   69  network restart
   70  systemctl restart network
   71  ifup
   72  systemctl restart systemd-networkd
   73  pacman-key --init
   74  ip addr
   75  networkctl 
   76  networkctl --help
   77  networkctl up wlan0
   78  networkctl 
   79  networkctl down wlan0
   80  networkctl 
   81  networkctl up wlan0
   82  networkctl 
   83  systemctl disable wpa_supplicant.conf
   84  systemctl disable wpa_supplicant
   85  systemctl stop wpa_supplicant
   86  networkctl down wlan0
   87  pacman-key --init
   88  networkctl 
   89  networkctl up wlan0
   90  networkctl 
   91  ip addr
   92  systemctl enable wpa_supplicant@wlan0.service
   93  systemctl restart systemd-networkd
   94  systemctl restart wpa_supplicant@wlan0.service
   95  ip a
   96  systemctl status wpa_supplicant@wlan0
   97  mv /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
   98  systemctl restart wpa_supplicant@wlan0.service
   99  systemctl status wpa_supplicant@wlan0
  100  systemctl stop wpa_supplicant
  101  systemctl disable wpa_supplicant
  102  systemctl enable wpa_supplicant@wlan0.service
  103  systemctl restart wpa_supplicant@wlan0.service
  104  systemctl status wpa_supplicant@wlan0.service
  105  reboot
  106  pacman-key --init
  107  ip a
  108  systemctl status wpa_supplicant@wlan0
  109  vim /etc/wpa_supplicant/wpa_supplicant-wlan0.conf 
  110  vi /etc/wpa_supplicant/wpa_supplicant-wlan0.conf 
  111  systemctl restart wpa_supplicant@wlan0
  112  ip addr
  113  vim /etc/
  114  vi /etc/systemd/network/wlan0.network 
  115  systemctl restart systemd-networkd
  116  ip a
  117  ping 141.1.1.1
  118  pacman -Syu
  119  pacman -S vim htop dstat
  120  file /bin/bash
  121  reboot
  122  ip a
  123  htop
  124  q
  125  pacman -Ss sane
  126  pacman -S sane
  127  pacman -Ss scanbd
  128  pacman -Ss scanner
  129  halt -p
  130  htop
  131  pacman -Qqe
  132  pacman -S sane-frontends
  133  pacman -S autoconf automake binutils gcc git imagemagick img2pdf 
  134  pacman -S base-devel
  135  pacman �-S trizen
  136  cd /tmp/
  137  git clone https://aur.archlinux.org/trizen-git.git && cd trizen-git && makepkg -si
  138  exit
  139  rm -rf trizen-git
  140  exit
  141  pacman -S sudo
  142  visudo 
  143  visudo 
  144  exit
  145  pacman -Syu
  146  sudo rm /var/lib/pacman/db.lck
  147  exit
  148  mv /tmp/scanbd.conf /etc/scanbd/
  149  cd /etc/scanbd/
  150  md5sum *
  151  mkdir scripts
  152  cd scripts
  153  mv /tmp/*.script /etc/scanbd/scripts/
  154  ls -lha
  155  exit
  156  cd /etc/scanbd/
  157  ls -lha
  158  chown root:root scanbd.conf
  159  ls -lha
  160  cd scripts
  161  ls -lha
  162  chwon root:root *
  163  chown root:root *
  164  ls -lha
  165  vim raspi1
  166  chown daemon:daemon raspi1 
  167  ls -lha
  168  cd ..
  169  vim scanbd.conf
  170  cd scrits
  171  cd scripts/
  172  ls -lha
  173  vim scan.script 
  174  pacman -Ss scanadf
  175  trizen -Ss scanadf
  176  exit
  177  cd /etc/scanbd/scripts/
  178  ls -lha
  179  chmod 600 raspi1 
  180  ls -lha
  181  systemctl start scanbd
  182  systemctl status scanbd
  183  systemctl enable scanbd
  184  journalctl -f
  185  reboot
  186  usermod -aG saned daemon
  187  cat /etc/group
  188  usermod -aG scanner alarm,daemon
  189  usermod -aG scanner alarm
  190  usermod -aG scanner daemon
  191  cat /etc/group
  192  systemctl restart scanbd
  193  ps -ef �| grep -i scan
  194  ps -ef 
  195  ps -ef | grep scan
  196  journalctl -f
  197  cat /etc/group
  198  reboot
  199  journalctl -f
  200  vim /etc/sane.d/fujitsu.conf 
  201  journalctl -f
  202  journalctl -r
  203  journalctl --unit=usb
  204  journalctl --grep=usb
  205  journalctl --grep="usb"
  206  journalctl --grep="usb" --since=2022-11-29
  207  vim /etc/sane.d/fujitsu.conf 
  208  vim /etc/sane.d/dll.conf 
  209  journalctl --grep="usb" --since=2022-11-29
  210  journalctl -f
  211  lsmod
  212  lspci 
  213  lsusb
  214  pacman -Ss lsusb
  215  cd /sys/bus/pci/drivers/
  216  ls -lha
  217  cd xhci_hcd/
  218  ls -lha
  219  lspci
  220  lsusb
  221  pacman -S usbutils
  222  lsusb
  223  pacman -
  224  pacman -S usbutils
  225  lsusb
  226  reboot
  227  lsusb
  228  systemctl status sane
  229  systemctl status saned
  230  ps -ef | grep -i sane
  231  journalctl -f
  232  systemctl status scanbd
  233  vim /etc/scanbd/scanbd.conf
  234  systemctl restart scanbd
  235  systemctl status scanbd
  236  systemctl stop scanbd
  237  /usr/sbin/scanbd -f -c /etc/scanbd/scanbd.conf
  238  lsusb
  239  watch lsusb
  240  reboot
  241  lsusb
  242  systemctl stop scanbd
  243  /usr/sbin/scanbd -f -c /etc/scanbd/scanbd.conf
  244  cat /etc/passwd
  245  cat /etc/group
  246  lsusb
  247  sudo -u daemon /usr/sbin/scanbd -f -c /etc/scanbd/scanbd.conf
  248  sudo -u daemon /bin/bash
  249  /usr/sbin/scanbd
  250  sudo -u daemon /usr/sbin/scanbd
  251  cd /etc/sane.d/
  252  ls
  253  cd /etc/scanbd/
  254  ls
  255  ls -lha
  256  rm -f sane.d
  257  mkdir -p sane.d
  258  cp -r /etc/sane.d/* /etc/scanbd/sane.d/
  259  vim /etc/sane.d/dll.conf 
  260  vim /etc/sane.d/net.conf 
  261  vim /etc/scanbd/sane.d/dll.conf 
  262  systemctl start scanbd
  263  systemctl status scanbd
  264  systemctl start scanbm.socket
  265  systemctl status scanbm.socket
  266  vim /etc/scanbd/scanbd.conf
  267  systemctl restart scanbd
  268  systemctl status scanbd
  269  systemctl status scanbd
  270  lsusb
  271  lsusb
  272  systemctl status scanbd
  273  systemctl status scanbd
  274  systemctl status scanbd
  275  pacman -Ss sane-frontends
  276  pacman -Ss sane-frontend
  277  pacman -Ss sane
  278  trizen -Ss sane-frontends
  279  exit
  280  ps -ef | grep -i scanbd
  281  systemctl stop scanbd
  282  /usr/sbin/scanbd -f -c /etc/scanbd/scanbd.conf
  283  trizen -Ss scanbd
  284  pacman -Ss scanbd
  285  exit
  286  lsusb
  287  cat /etc/udev/rules.d/40-scanner.rules
  288  history

```