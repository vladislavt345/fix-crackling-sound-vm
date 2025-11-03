systemctl --user stop pipewire pipewire-pulse wireplumber
systemctl --user mask pipewire-pulse

sudo zypper install -y pulseaudio pulseaudio-utils

mkdir -p ~/.config/pulse

cat > ~/.config/pulse/daemon.conf << 'EOF'
default-sample-format = s16le
default-sample-rate = 48000
alternate-sample-rate = 48000
default-sample-channels = 2
default-fragments = 4
default-fragment-size-msec = 10
high-priority = yes
nice-level = -11
realtime-scheduling = yes
realtime-priority = 9
resample-method = speex-float-1
avoid-resampling = yes
enable-remixing = no
exit-idle-time = -1
EOF

cat > ~/.config/pulse/default.pa << 'EOF'
#!/usr/bin/pulseaudio -nF
.include /etc/pulse/default.pa
load-module module-alsa-sink device=hw:0,0 tsched=0 fragments=4 fragment_size=5120
load-module module-alsa-source device=hw:0,0 tsched=0
set-default-sink alsa_output.hw_0_0
EOF

cat > ~/.asoundrc << 'EOF'
defaults.pcm.rate_converter "speexrate_medium"
pcm.!default {
    type plug
    slave.pcm "dmixer"
}
pcm.dmixer {
    type dmix
    ipc_key 1024
    slave {
        pcm "hw:0,0"
        rate 48000
        period_time 0
        period_size 512
        buffer_size 2048
    }
}
EOF

pulseaudio --kill 2>/dev/null || true
sleep 1
pulseaudio --start
sleep 2
