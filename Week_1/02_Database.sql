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

-- nhom c: group by
--Đếm số nhân viên của từng phòng
-- LEFT JOIN để phòng chưa có nhân viên vẫn hiện ra với số đếm = 0
select pb.MaPB, pb.TenPB, COUNT(nv.MaNV) AS SoNhanVien
from PHONGBAN pb
left join NHANVIEN nv ON nv.MaPB = pb.MaPB
group by pb.MaPB, pb.TenPB
order by SoNhanVien desc

--Tính lương trung bình của từng phòng
select pb.TenPB, AVG(nv.Luong) AS LuongTrungBinh
from PHONGBAN pb
join NHANVIEN nv ON nv.MaPB = pb.MaPB
group by pb.TenPB

--Tìm phòng ban có mức lương trung bình cao nhất
-- WITH TIES: nếu có 2 phòng bằng điểm cao nhất thì lấy hết, không bỏ sót
select top 1 with ties pb.TenPB, AVG(nv.Luong) AS LuongTrungBinh
from PHONGBAN pb
join NHANVIEN nv ON nv.MaPB = pb.MaPB
group by pb.TenPB
order by AVG(nv.Luong) desc

--Đếm số dự án do từng phòng phụ trách
select pb.MaPB, pb.TenPB, COUNT(da.MaDA) AS SoDuAn
from PHONGBAN pb
left join DUAN da ON da.MaPB_ChuTri = pb.MaPB
group by pb.MaPB, pb.TenPB
order by SoDuAn desc

--Tính tổng số giờ mà mỗi nhân viên đã làm trên tất cả dự án
select nv.MaNV, nv.HoTen, SUM(tg.SoGioDaThucHien) AS TongSoGio
from NHANVIEN nv
join THAMGIA tg ON tg.MaNV = nv.MaNV
group by nv.MaNV, nv.HoTen
order by TongSoGio desc

--Tính tổng số giờ thực hiện của từng dự án
select da.MaDA, da.TenDA, SUM(tg.SoGioDaThucHien) AS TongSoGio
from DUAN da
join THAMGIA tg ON tg.MaDA = da.MaDA
group by da.MaDA, da.TenDA
order by TongSoGio desc

--Tìm số người tham gia từng dự án
select da.MaDA, da.TenDA, COUNT(tg.MaNV) AS SoNguoiThamGia
from DUAN da
left join THAMGIA tg ON tg.MaDA = da.MaDA
group by da.MaDA, da.TenDA
order by SoNguoiThamGia desc

--Tìm các dự án có ít nhất 5 nhân viên tham gia
-- HAVING = điều kiện lọc SAU khi gom nhóm (WHERE lọc trước khi gom nhóm)
select da.MaDA, da.TenDA, COUNT(tg.MaNV) AS SoNhanVien
from DUAN da
join THAMGIA tg ON tg.MaDA = da.MaDA
group by da.MaDA, da.TenDA
having COUNT(tg.MaNV) >= 5

--Tìm các phòng có ít nhất 6 nhân viên
select pb.MaPB, pb.TenPB, COUNT(nv.MaNV) AS SoNhanVien
from PHONGBAN pb
join NHANVIEN nv ON nv.MaPB = pb.MaPB
group by pb.MaPB, pb.TenPB
having COUNT(nv.MaNV) >= 6

--Tìm nhân viên tham gia từ 3 dự án trở lên
select nv.MaNV, nv.HoTen, COUNT(tg.MaDA) AS SoDuAnThamGia
from NHANVIEN nv
join THAMGIA tg ON tg.MaNV = nv.MaNV
group by nv.MaNV, nv.HoTen
having COUNT(tg.MaDA) >= 3

--nhóm D: subquery 
--Tìm nhân viên có lương cao hơn lương trung bình toàn công ty
select nv.MaNV, nv.HoTen, nv.Luong
from NHANVIEN nv
where nv.Luong > (select AVG(Luong) from NHANVIEN)

--Tìm nhân viên có lương cao hơn lương trung bình của chính phòng ban mình
-- subquery tương quan: mỗi dòng nv sẽ tính lại AVG riêng cho phòng của nó
select nv.MaNV, nv.HoTen, nv.Luong, nv.MaPB
from NHANVIEN nv
where nv.Luong > (select AVG(nv2.Luong)
                  from NHANVIEN nv2
                  where nv2.MaPB = nv.MaPB)

--Tìm nhân viên có mức lương cao nhất trong công ty
select nv.MaNV, nv.HoTen, nv.Luong
from NHANVIEN nv
where nv.Luong = (select MAX(Luong) from NHANVIEN)

--Tìm nhân viên có mức lương cao nhất của từng phòng
select nv.MaNV, nv.HoTen, nv.MaPB, nv.Luong
from NHANVIEN nv
where nv.Luong = (select MAX(nv2.Luong)
                  from NHANVIEN nv2
                  where nv2.MaPB = nv.MaPB)
order by nv.MaPB

--Tìm dự án có nhiều nhân viên tham gia nhất
select da.MaDA, da.TenDA, COUNT(tg.MaNV) AS SoNhanVien
from DUAN da
join THAMGIA tg ON tg.MaDA = da.MaDA
group by da.MaDA, da.TenDA
having COUNT(tg.MaNV) = (select MAX(SoNV)
                         from (select COUNT(MaNV) AS SoNV
                               from THAMGIA
                               group by MaDA) AS T)

--Tìm nhân viên có tổng số giờ làm dự án lớn nhất
select nv.MaNV, nv.HoTen, SUM(tg.SoGioDaThucHien) AS TongSoGio
from NHANVIEN nv
join THAMGIA tg ON tg.MaNV = nv.MaNV
group by nv.MaNV, nv.HoTen
having SUM(tg.SoGioDaThucHien) = (select MAX(TongGio)
                                  from (select SUM(SoGioDaThucHien) AS TongGio
                                        from THAMGIA
                                        group by MaNV) AS T)

--Tìm những nhân viên chưa tham gia dự án nào
select nv.MaNV, nv.HoTen
from NHANVIEN nv
where nv.MaNV not in (select MaNV from THAMGIA)

--Tìm những phòng ban chưa phụ trách dự án nào
select pb.MaPB, pb.TenPB
from PHONGBAN pb
where pb.MaPB not in (select MaPB_ChuTri from DUAN)

-- nhóm e: exits/not exists
--Tìm nhân viên có ít nhất một người con
-- EXISTS chỉ kiểm tra "có tồn tại dòng nào không", không quan tâm select gì bên trong
select nv.MaNV, nv.HoTen
from NHANVIEN nv
where exists (select 1 from CON c where c.MaNV = nv.MaNV)

--Tìm nhân viên không có người con nào
select nv.MaNV, nv.HoTen
from NHANVIEN nv
where not exists (select 1 from CON c where c.MaNV = nv.MaNV)

--Tìm nhân viên có tham gia ít nhất một dự án do phòng khác phụ trách
select nv.MaNV, nv.HoTen, nv.MaPB
from NHANVIEN nv
where exists (select 1
              from THAMGIA tg
              join DUAN da ON da.MaDA = tg.MaDA
              where tg.MaNV = nv.MaNV
                and da.MaPB_ChuTri <> nv.MaPB)

--Tìm các dự án mà không có nhân viên thuộc phòng phụ trách dự án tham gia
select da.MaDA, da.TenDA, da.MaPB_ChuTri
from DUAN da
where not exists (select 1
                  from THAMGIA tg
                  join NHANVIEN nv ON nv.MaNV = tg.MaNV
                  where tg.MaDA = da.MaDA
                    and nv.MaPB = da.MaPB_ChuTri)

--Tìm các phòng ban mà tất cả nhân viên đều đã tham gia ít nhất một dự án
-- ý tưởng: không tồn tại nhân viên nào của phòng mà chưa tham gia dự án nào
select pb.MaPB, pb.TenPB
from PHONGBAN pb
where not exists (select 1
                  from NHANVIEN nv
                  where nv.MaPB = pb.MaPB
                    and not exists (select 1
                                    from THAMGIA tg
                                    where tg.MaNV = nv.MaNV))

-- nhóm f Truy vấn khó
--Tìm nhân viên tham gia tất cả các dự án do phòng mình phụ trách
-- phép chia quan hệ: không tồn tại dự án nào của phòng mình mà mình chưa tham gia
select nv.MaNV, nv.HoTen, nv.MaPB
from NHANVIEN nv
where not exists (select 1
                  from DUAN da
                  where da.MaPB_ChuTri = nv.MaPB
                    and not exists (select 1
                                    from THAMGIA tg
                                    where tg.MaNV = nv.MaNV
                                      and tg.MaDA = da.MaDA))
  and exists (select 1 from DUAN da2 where da2.MaPB_ChuTri = nv.MaPB)



--Tìm nhân viên tham gia nhiều dự án nhất
select top 1 with ties nv.MaNV, nv.HoTen, COUNT(tg.MaDA) AS SoDuAn
from NHANVIEN nv
join THAMGIA tg ON tg.MaNV = nv.MaNV
group by nv.MaNV, nv.HoTen
order by COUNT(tg.MaDA) desc;

--Tìm nhân viên có tổng số giờ cao nhất trong từng phòng
-- gom tổng giờ theo nhân viên trước, rồi xếp hạng trong từng phòng
with TongGio AS (
    select nv.MaNV, nv.HoTen, nv.MaPB, SUM(tg.SoGioDaThucHien) AS TongSoGio
    from NHANVIEN nv
    join THAMGIA tg ON tg.MaNV = nv.MaNV
    group by nv.MaNV, nv.HoTen, nv.MaPB
)
select MaNV, HoTen, MaPB, TongSoGio
from (select *, RANK() over (partition by MaPB order by TongSoGio desc) AS Hang
      from TongGio) AS T
where Hang = 1

--Tìm dự án có tổng chi phí phụ cấp nhân viên cao nhất
select top 1 with ties da.MaDA, da.TenDA, SUM(tg.MucPhuCapDuAn) AS TongPhuCap
from DUAN da
join THAMGIA tg ON tg.MaDA = da.MaDA
group by da.MaDA, da.TenDA
order by SUM(tg.MucPhuCapDuAn) desc

--Tìm 3 nhân viên có tổng số giờ dự án cao nhất
select top 3 with ties nv.MaNV, nv.HoTen, SUM(tg.SoGioDaThucHien) AS TongSoGio
from NHANVIEN nv
join THAMGIA tg ON tg.MaNV = nv.MaNV
group by nv.MaNV, nv.HoTen
order by SUM(tg.SoGioDaThucHien) desc

--Với mỗi phòng ban, tìm 2 nhân viên có mức lương cao nhất
select MaNV, HoTen, TenPB, Luong
from (select nv.MaNV, nv.HoTen, pb.TenPB, nv.Luong,
             ROW_NUMBER() over (partition by nv.MaPB order by nv.Luong desc) AS STT
      from NHANVIEN nv
      join PHONGBAN pb ON pb.MaPB = nv.MaPB) AS T
where STT <= 2
order by TenPB, Luong desc

--Xếp hạng nhân viên trong từng phòng theo mức lương
select nv.MaNV, nv.HoTen, pb.TenPB, nv.Luong,
       DENSE_RANK() over (partition by nv.MaPB order by nv.Luong desc) AS HangLuong
from NHANVIEN nv
join PHONGBAN pb ON pb.MaPB = nv.MaPB
order by pb.TenPB, HangLuong

--Xếp hạng các dự án theo tổng số giờ thực hiện
select da.MaDA, da.TenDA, SUM(tg.SoGioDaThucHien) AS TongSoGio,
       RANK() over (order by SUM(tg.SoGioDaThucHien) desc) AS Hang
from DUAN da
join THAMGIA tg ON tg.MaDA = da.MaDA
group by da.MaDA, da.TenDA

--Tìm nhân viên có mức lương lớn hơn người giám sát trực tiếp
-- self join: cùng 1 bảng NHANVIEN nhưng đặt 2 bí danh khác nhau
select nv.HoTen AS NhanVien, nv.Luong AS LuongNV,
       gs.HoTen AS NguoiGiamSat, gs.Luong AS LuongGiamSat
from NHANVIEN nv
join NHANVIEN gs ON nv.MaNV_GiamSat = gs.MaNV
where nv.Luong > gs.Luong;

--Tìm nhân viên có số dự án tham gia lớn hơn người giám sát của mình
with SoDA AS (
    select MaNV, COUNT(MaDA) AS SoDuAn
    from THAMGIA
    group by MaNV
)
select nv.HoTen AS NhanVien, ISNULL(a.SoDuAn,0) AS SoDA_NhanVien,
       gs.HoTen AS NguoiGiamSat, ISNULL(b.SoDuAn,0) AS SoDA_GiamSat
from NHANVIEN nv
join NHANVIEN gs ON nv.MaNV_GiamSat = gs.MaNV
left join SoDA a ON a.MaNV = nv.MaNV
left join SoDA b ON b.MaNV = gs.MaNV
where ISNULL(a.SoDuAn,0) > ISNULL(b.SoDuAn,0)

--Tìm người giám sát có số nhân viên cấp dưới trực tiếp nhiều nhất
select top 1 with ties gs.MaNV, gs.HoTen, COUNT(nv.MaNV) AS SoCapDuoi
from NHANVIEN gs
join NHANVIEN nv ON nv.MaNV_GiamSat = gs.MaNV
group by gs.MaNV, gs.HoTen
order by COUNT(nv.MaNV) desc

--Tìm các nhân viên không phải trưởng phòng nhưng có lương lớn hơn trưởng phòng của mình
select nv.HoTen AS NhanVien, nv.Luong AS LuongNV,
       tp.HoTen AS TruongPhong, tp.Luong AS LuongTruongPhong, pb.TenPB
from NHANVIEN nv
join PHONGBAN pb ON pb.MaPB = nv.MaPB
join NHANVIEN tp ON tp.MaNV = pb.MaTruongPhong
where nv.MaNV <> pb.MaTruongPhong
  and nv.Luong > tp.Luong;

--nhóm g: truy vấn đệ quy

--Với một nhân viên bất kỳ, tìm toàn bộ chuỗi người giám sát từ nhân viên đó lên đến giám đốc
-- đổi 'NV015' thành mã nhân viên bạn muốn kiểm tra
with ChuoiGiamSat AS (
    -- neo: chính nhân viên cần xét
    select nv.MaNV, nv.HoTen, nv.MaNV_GiamSat, 0 AS Cap
    from NHANVIEN nv
    where nv.MaNV = 'NV015'

    union all

    -- đệ quy: leo lên người giám sát của cấp trước đó
    select gs.MaNV, gs.HoTen, gs.MaNV_GiamSat, c.Cap + 1
    from NHANVIEN gs
    join ChuoiGiamSat c ON c.MaNV_GiamSat = gs.MaNV
)
select Cap, MaNV, HoTen
from ChuoiGiamSat
order by Cap;

--Với một người quản lý, tìm toàn bộ nhân viên cấp dưới trực tiếp và gián tiếp
-- đổi 'NV002' thành mã người quản lý cần xét
with CapDuoi AS (
    select nv.MaNV, nv.HoTen, nv.MaNV_GiamSat, 1 AS Cap
    from NHANVIEN nv
    where nv.MaNV_GiamSat = 'NV002'

    union all

    select nv.MaNV, nv.HoTen, nv.MaNV_GiamSat, cd.Cap + 1
    from NHANVIEN nv
    join CapDuoi cd ON nv.MaNV_GiamSat = cd.MaNV
)
select Cap, MaNV, HoTen
from CapDuoi
order by Cap, MaNV;

--Hiển thị cây quản lý của toàn công ty
-- DuongDan dùng để sắp xếp cho đúng thứ tự cha trước con sau
with CayQuanLy AS (
    select nv.MaNV, nv.HoTen, nv.MaNV_GiamSat, 0 AS Cap,
           CAST(nv.HoTen AS NVARCHAR(1000)) AS DuongDan
    from NHANVIEN nv
    where nv.MaNV_GiamSat IS NULL

    union all

    select nv.MaNV, nv.HoTen, nv.MaNV_GiamSat, c.Cap + 1,
           CAST(c.DuongDan + N' > ' + nv.HoTen AS NVARCHAR(1000))
    from NHANVIEN nv
    join CayQuanLy c ON nv.MaNV_GiamSat = c.MaNV
)
select Cap,
       REPLICATE(N'    ', Cap) + CASE WHEN Cap = 0 THEN N'' ELSE N'→ ' END + HoTen AS CayQuanLy,
       MaNV
from CayQuanLy
order by DuongDan