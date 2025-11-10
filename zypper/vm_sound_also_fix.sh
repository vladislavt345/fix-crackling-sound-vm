mkdir -p ~/.config/pipewire/pipewire.conf.d
cat > ~/.config/pipewire/pipewire.conf.d/99-vmware.conf << 'EOF'
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 512
    default.clock.min-quantum = 128
    default.clock.max-quantum = 1024
}
context.modules = [
    {   name = libpipewire-module-rtkit
        args = {
            nice.level = -11
            rt.prio = 20
            rt.time.soft = 200000
            rt.time.hard = 200000
        }
        flags = [ ifexists nofail ]
    }
]
EOF

mkdir -p ~/.config/wireplumber/main.lua.d
cat > ~/.config/wireplumber/main.lua.d/51-vmware-audio.lua << 'EOF'
rule = {
  matches = {
    {
      { "node.name", "matches", "alsa_output.*" },
    },
  },
  apply_properties = {
    ["audio.rate"] = 48000,
    ["api.alsa.period-size"] = 512,
    ["api.alsa.headroom"] = 1024,
  },
}
table.insert(alsa_monitor.rules, rule)
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

if [ ! -f /etc/security/limits.d/audio.conf ]; then
    echo "@audio - rtprio 95
@audio - memlock unlimited
@audio - nice -19" | sudo tee /etc/security/limits.d/audio.conf > /dev/null
fi

if ! groups | grep -q audio; then
    sudo usermod -aG audio $USER
fi

mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/pipewire.conf << 'EOF'
PIPEWIRE_LATENCY=512/48000
EOF

systemctl --user daemon-reload
systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null
sleep 2
