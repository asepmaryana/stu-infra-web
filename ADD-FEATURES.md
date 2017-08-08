Kirim SMS dari Server ke list operator, jika kondisi : 

update cdc :
1. sms notif bila teg battery < 47 (default 47, tpi bisa diubah) [done]
2. sms notif bila tidak ada sms yang masuk selama 6 jam (default 6 jam bisa diubah) [done]
3. sms notif bila ada alarm genset fail dari site [done]
4. sms notif bila ada low fuel [done]
5. time update diambil dari waktu sending/jam operator, bukan dari timestamp isi sms sinegen [done]
6. alarm popup dihilangkan [done]
7. sms notif bila ada perubahan jadwal piket [done]

list operator senen-minggu

on progress:
1. clear/delete alarm aktif [done]
2. pada tree menu ditambahkan status alarm pada setiap region, area dan node sinegen 