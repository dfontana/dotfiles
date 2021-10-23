## Fan Control

You need to first get the python deps setup; eg:

```bash
cd liquidctl
pip install .
pip install psutil
cd extra
sudo pip install psutil
```

Setup:
```bash
sudo ./link-systemd.sh
systemctl daemon-reload
systemctl start liquidcfg fan2 fan3
systemctl enable liquidcfg fan2 fan3
```
