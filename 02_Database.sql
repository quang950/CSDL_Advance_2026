--Nhom A
--liệt kê toàn bộ nhân viên
SELECT * FROM NHANVIEN;

--Liệt kê họ tên, ngày sinh, lương và phòng ban của nhân viên
SELECT HoTen,NgaySinh,Luong,MaPB
from NHANVIEN

--Tìm nhân viên có lương trên 20 triệu
select * From NHANVIEN
where Luong > 20000000

--Tìm nhân viên vào làm trong năm 2025.
select * from NHANVIEN
where NgayVaoLam>'2025-01-01' AND NgayVaoLam <'2026-01-01'

-- Tìm các dự án đang thực hiện.
select * from DUAN
where TrangThai = 'Dang thuc hien'

-- Tìm các dự án do một phòng ban cụ thể phụ trách.
select * from DUAN
where MaPB_ChuTri = 'PB01'

--Liệt kê nhân viên theo thứ tự lương giảm dần
select HoTen, Luong From NHANVIEN
order by Luong DESC

-- Liệt kê các mức lương khác nhau đang tồn tại trong công ty.
-- dùng distinct để loại bỏ các giá trị trùng lặp
select distinct Luong from NHANVIEN
order by Luong Desc

--NhomB
--Liệt kê nhân viên cùng tên phòng ban.
select nv.HoTen , pb.TenPB
From NHANVIEN nv 
JOIN PHONGBAN pb ON nv.MaPB = pb.MaPB

--Liệt kê dự án và tên phòng ban phụ trách
select da.TenDA , pb.TenPB 
from DUAN da 
join PHONGBAN pb ON da.MaPB_ChuTri = pb.MaPB

--Liệt kê tên nhân viên, dự án tham gia, vai trò và số giờ làm việc
select nv.HoTen,da.TenDA,tg.VaiTro , tg.SoGioDaThucHien
from THAMGIA tg 
join NHANVIEN nv ON tg.MaNV = nv.manv
join DUAN da ON tg.MaDA = da.MaDA

-- Liệt kê tên nhân viên và tên người giám sát trực tiếp
-- dùng AS để đặt tên cho cột mới khi cột gốc dễ gây hiểu lầm hoặc trùng
select nv.hoten AS Nhanvien , gs.HoTen As NguoiGiamSat
from NHANVIEN nv
left join nhanvien gs On nv.MaNV_GiamSat = gs.MaNV;

--Liệt kê tên trưởng phòng của từng phòng ban
-- nói đơn giản , AS giống như đặt tên cho 1 cột mới mà mình muốn xuất ra
select pb.TenPB , nv.HoTen AS TruongPhong
from PHONGBAN pb 
join NHANVIEN nv ON pb.MaTruongPhong = nv.MaNV

--Liệt kê các nhân viên tham gia dự án không do phòng ban của mình phụ trách.
select distinct nv.HoTen , da.TenDA , nv.MaPB AS PhongNhanVien,da.MaPB_ChuTri AS PhongChuTri
From THAMGIA tg
join NHANVIEN nv On tg.MaNV = nv.MaNV
join DUAN da ON tg.MaDA = da.MaDA
where nv.MaPB <> da.MaPB_ChuTri

select * from THAMGIA