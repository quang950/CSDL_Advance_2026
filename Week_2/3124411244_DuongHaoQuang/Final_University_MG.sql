-- ============================================================
-- FILE TỔNG HỢP: TẠO CSDL + RÀNG BUỘC + DỮ LIỆU KIỂM THỬ + TRUY VẤN
-- Gồm 3 phần theo đúng thứ tự chạy:
--   1. RangBuoc_MU.sql       : tạo bảng, ràng buộc, trigger sĩ số
--   2. insert_Data_Kiemthu.sql : dữ liệu kiểm thử + test vi phạm ràng buộc
--   3. Phần D & E             : truy vấn SQL (câu 1-30) và bài tập nâng cao (câu 31-35)
-- ============================================================

-- ================= PHẦN 1: RangBuoc_MU.sql =================

CREATE DATABASE QuanLyDaoTao;
GO
USE QuanLyDaoTao;
GO

--  KHOA
CREATE TABLE KHOA (
    MaKhoa      VARCHAR(10)   NOT NULL,
    TenKhoa     NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_KHOA PRIMARY KEY (MaKhoa)
);
GO

--  NGANH
CREATE TABLE NGANH (
    MaNganh     VARCHAR(10)   NOT NULL,
    TenNganh    NVARCHAR(100) NOT NULL,
    MaKhoa      VARCHAR(10)   NOT NULL,
    CONSTRAINT PK_NGANH PRIMARY KEY (MaNganh),
    CONSTRAINT FK_NGANH_KHOA FOREIGN KEY (MaKhoa) REFERENCES KHOA(MaKhoa)
);
GO

--  BO_MON
-- MaTruongBM để NULL và chưa có FK ở đây, vì GIANG_VIEN chưa tồn tại
-- (2 bảng BO_MON <-> GIANG_VIEN tham chiếu vòng lẫn nhau).
-- FK này sẽ được thêm bằng ALTER TABLE ngay sau khi tạo xong GIANG_VIEN.
CREATE TABLE BO_MON (
    MaBM        VARCHAR(10)   NOT NULL,
    TenBM       NVARCHAR(100) NOT NULL,
    MaKhoa      VARCHAR(10)   NOT NULL,
    MaTruongBM  VARCHAR(10)   NULL,
    CONSTRAINT PK_BOMON PRIMARY KEY (MaBM),
    CONSTRAINT FK_BOMON_KHOA FOREIGN KEY (MaKhoa) REFERENCES KHOA(MaKhoa)
);
GO

--  GIANG_VIEN
CREATE TABLE GIANG_VIEN (
    MaGV        VARCHAR(10)   NOT NULL,
    TenGV       NVARCHAR(100) NOT NULL,
    MaBM        VARCHAR(10)   NOT NULL,
    CONSTRAINT PK_GIANGVIEN PRIMARY KEY (MaGV),
    CONSTRAINT FK_GIANGVIEN_BOMON FOREIGN KEY (MaBM) REFERENCES BO_MON(MaBM)
);
GO

-- Bổ sung FK còn thiếu của BO_MON (ràng buộc 6): trưởng bộ môn phải là 1 giảng viên đã tồn tại.
-- Lưu ý: FK chỉ đảm bảo MaTruongBM là MaGV có thật, KHÔNG đảm bảo giảng viên đó
-- thuộc đúng bộ môn mình làm trưởng (ràng buộc 5) -> phần đó xử lý bằng trigger, xem cuối file.
ALTER TABLE BO_MON
    ADD CONSTRAINT FK_BOMON_TRUONGBM FOREIGN KEY (MaTruongBM) REFERENCES GIANG_VIEN(MaGV);
GO

--  LOP_HANH_CHINH
CREATE TABLE LOP_HANH_CHINH (
    MaLop       VARCHAR(10)   NOT NULL,
    TenLop      NVARCHAR(100) NOT NULL,
    MaNganh     VARCHAR(10)   NOT NULL,
    CONSTRAINT PK_LOPHANHCHINH PRIMARY KEY (MaLop),
    CONSTRAINT FK_LOPHC_NGANH FOREIGN KEY (MaNganh) REFERENCES NGANH(MaNganh)
);
GO

--  SINH_VIEN
CREATE TABLE SINH_VIEN (
    MaSV        VARCHAR(10)   NOT NULL,
    TenSV       NVARCHAR(100) NOT NULL,
    MaLop       VARCHAR(10)   NOT NULL,
    CONSTRAINT PK_SINHVIEN PRIMARY KEY (MaSV),
    CONSTRAINT FK_SINHVIEN_LOP FOREIGN KEY (MaLop) REFERENCES LOP_HANH_CHINH(MaLop)
);
GO

--  HOC_PHAN
CREATE TABLE HOC_PHAN (
    MaHP        VARCHAR(10)   NOT NULL,
    TenHP       NVARCHAR(100) NOT NULL,
    SoTinChi    INT           NOT NULL,
    CONSTRAINT PK_HOCPHAN PRIMARY KEY (MaHP),
    -- Ràng buộc B.1: số tín chỉ từ 1 đến 6
    CONSTRAINT CK_HOCPHAN_TINCHI CHECK (SoTinChi BETWEEN 1 AND 6)
);
GO

--  CHUONG_TRINH_DAO_TAO (quan hệ N:N Ngành - Học phần)
CREATE TABLE CHUONG_TRINH_DAO_TAO (
    MaNganh     VARCHAR(10) NOT NULL,
    MaHP        VARCHAR(10) NOT NULL,
    LoaiHP      VARCHAR(2)  NOT NULL,   -- 'BB' = Bắt buộc, 'TC' = Tự chọn
    -- Ràng buộc B.11: mỗi cặp (Ngành, Học phần) chỉ xuất hiện 1 lần -> đã đảm bảo bởi PK
    CONSTRAINT PK_CTDT PRIMARY KEY (MaNganh, MaHP),
    CONSTRAINT FK_CTDT_NGANH FOREIGN KEY (MaNganh) REFERENCES NGANH(MaNganh),
    CONSTRAINT FK_CTDT_HOCPHAN FOREIGN KEY (MaHP) REFERENCES HOC_PHAN(MaHP),
    -- Ràng buộc B.12: LoaiHP chỉ nhận BB hoặc TC
    CONSTRAINT CK_CTDT_LOAIHP CHECK (LoaiHP IN ('BB','TC'))
);
GO

--  HOC_PHAN_TIEN_QUYET (quan hệ N:N Học phần - chính nó)
CREATE TABLE HOC_PHAN_TIEN_QUYET (
    MaHP            VARCHAR(10) NOT NULL,  -- học phần đang xét
    MaHP_TienQuyet  VARCHAR(10) NOT NULL,  -- học phần tiên quyết của nó
    CONSTRAINT PK_HPTQ PRIMARY KEY (MaHP, MaHP_TienQuyet),
    CONSTRAINT FK_HPTQ_HP FOREIGN KEY (MaHP) REFERENCES HOC_PHAN(MaHP),
    CONSTRAINT FK_HPTQ_HPTQ FOREIGN KEY (MaHP_TienQuyet) REFERENCES HOC_PHAN(MaHP),
    -- Ràng buộc B.9: một học phần không thể là tiên quyết trực tiếp của chính nó
    CONSTRAINT CK_HPTQ_KHACNHAU CHECK (MaHP <> MaHP_TienQuyet)
    -- Ràng buộc B.10 (không chu trình A->B->C->A) KHÔNG cài được bằng CHECK
    -- vì CHECK chỉ xét được 1 dòng, không so sánh được toàn bộ đồ thị -> xử lý bằng trigger (xem cuối file)
);
GO

--  LOP_HOC_PHAN
CREATE TABLE LOP_HOC_PHAN (
    MaLHP       VARCHAR(10) NOT NULL,
    MaHP        VARCHAR(10) NOT NULL,
    MaGVPT      VARCHAR(10) NOT NULL,   -- giảng viên phụ trách chính
    HocKy       INT         NOT NULL,
    NamHoc      VARCHAR(9)  NOT NULL,   -- vd '2024-2025'
    PhongHoc    VARCHAR(20) NOT NULL,
    SiSoToiDa   INT         NOT NULL,
    CONSTRAINT PK_LOPHOCPHAN PRIMARY KEY (MaLHP),
    -- Ràng buộc B.6: mỗi lớp học phần thuộc đúng 1 học phần -> cột MaHP NOT NULL + FK
    CONSTRAINT FK_LHP_HOCPHAN FOREIGN KEY (MaHP) REFERENCES HOC_PHAN(MaHP),
    -- Ràng buộc B.7: mỗi lớp học phần có đúng 1 giảng viên phụ trách chính -> cột MaGVPT NOT NULL + FK
    CONSTRAINT FK_LHP_GIANGVIEN FOREIGN KEY (MaGVPT) REFERENCES GIANG_VIEN(MaGV),
    -- Ràng buộc B.3: sĩ số tối đa phải > 0
    CONSTRAINT CK_LHP_SISO CHECK (SiSoToiDa > 0)
);
GO

--  DANG_KY
CREATE TABLE DANG_KY (
    MaSV            VARCHAR(10) NOT NULL,
    MaLHP           VARCHAR(10) NOT NULL,
    NgayDangKy      DATE        NOT NULL,   -- ràng buộc B.13: không được để trống -> NOT NULL
    DiemChuyenCan   DECIMAL(4,2) NULL,
    DiemGiuaKy      DECIMAL(4,2) NULL,
    DiemCuoiKy      DECIMAL(4,2) NULL,
    -- Ràng buộc B.4: 1 sinh viên không đăng ký 2 lần cùng 1 lớp học phần -> đảm bảo bởi PK
    CONSTRAINT PK_DANGKY PRIMARY KEY (MaSV, MaLHP),
    -- Ràng buộc B.14: SV và LHP tham chiếu phải tồn tại -> đảm bảo bởi FK
    CONSTRAINT FK_DK_SINHVIEN FOREIGN KEY (MaSV) REFERENCES SINH_VIEN(MaSV),
    CONSTRAINT FK_DK_LOPHOCPHAN FOREIGN KEY (MaLHP) REFERENCES LOP_HOC_PHAN(MaLHP),
    -- Ràng buộc B.2: điểm nếu có phải trong khoảng 0-10
    CONSTRAINT CK_DK_CHUYENCAN CHECK (DiemChuyenCan IS NULL OR DiemChuyenCan BETWEEN 0 AND 10),
    CONSTRAINT CK_DK_GIUAKY    CHECK (DiemGiuaKy    IS NULL OR DiemGiuaKy    BETWEEN 0 AND 10),
    CONSTRAINT CK_DK_CUOIKY    CHECK (DiemCuoiKy    IS NULL OR DiemCuoiKy    BETWEEN 0 AND 10)
);
GO

-- CÁC RÀNG BUỘC KHÔNG CÀI ĐƯỢC BẰNG PK/FK/CHECK -> XỬ LÝ RIÊNG

-- Ràng buộc B.15: KHÔNG tạo cột "TinChiTichLuy" / "GPA" trong bảng SINH_VIEN.
-- Đây chính là cách cài đặt ràng buộc "không lưu dư thừa dữ liệu suy diễn được":
-- 2 giá trị này sẽ được TÍNH từ DANG_KY + HOC_PHAN bằng truy vấn/VIEW (xem Câu 29, Câu 34),
-- không lưu cứng trong bảng để tránh sai lệch khi điểm thay đổi.

-- Ràng buộc B.8: không được thêm ĐĂNG KÝ nếu làm lớp vượt sĩ số tối đa.
-- Không dùng CHECK được vì CHECK chỉ xét được giá trị trong CHÍNH dòng đang ghi,
-- không được phép SELECT COUNT(*) sang bảng khác để so sánh.
-- -> dùng TRIGGER "INSTEAD OF INSERT": trigger này thay thế hoàn toàn lệnh INSERT gốc,
--    cho phép mình kiểm tra điều kiện TRƯỚC rồi mới tự tay ghi dữ liệu vào bảng.
-- "inserted" là bảng ảo (pseudo-table) do SQL Server tự tạo, chứa các dòng người dùng đang cố insert.
CREATE TRIGGER TRG_DANGKY_KIEMTRA_SISO
ON DANG_KY
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Từ chối cả batch nếu có ít nhất 1 lớp học phần bị vượt sĩ số sau khi cộng thêm các dòng mới
    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT MaLHP FROM inserted) i
        JOIN LOP_HOC_PHAN l ON l.MaLHP = i.MaLHP
        WHERE
            (SELECT COUNT(*) FROM DANG_KY  d WHERE d.MaLHP = i.MaLHP)   -- SV đã đăng ký từ trước
          + (SELECT COUNT(*) FROM inserted i2 WHERE i2.MaLHP = i.MaLHP) -- SV đang đăng ký thêm (batch hiện tại)
          > l.SiSoToiDa
    )
    BEGIN
        RAISERROR(N'Lớp học phần đã đủ sĩ số, không thể đăng ký thêm.', 16, 1);
        RETURN;
    END

    INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy)
    SELECT MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy
    FROM inserted;
END;
GO

-- Ràng buộc B.5 (trưởng bộ môn phải thuộc chính bộ môn đó) và B.10 (tiên quyết không
-- được tạo chu trình) cũng cần trigger, nhưng cả 2 đều liên quan trực tiếp tới Câu 35
-- (đề bài cho phép chưa bắt buộc cài hoàn chỉnh nếu chưa học đệ quy/trigger) nên mình sẽ
-- viết cùng lúc với Câu 35 ở cuối file, sau khi đã có dữ liệu kiểm thử để test luôn cho tiện.
GO

-- ================= PHẦN 2: insert_Data_Kiemthu.sql =================

-- CÂU 7. DỮ LIỆU KIỂM THỬ
-- Quy mô: 2 khoa, 4 bộ môn, 8 giảng viên, 3 ngành, 5 lớp hành chính,
--         20 sinh viên, 12 học phần, 3 học kỳ, 15 lớp học phần, 63 lượt đăng ký.
-- Các tình huống chủ động tạo ra được đánh dấu bằng comment tại chỗ tương ứng.
use QuanLyDaoTao
-- KHOA (2)
INSERT INTO KHOA (MaKhoa, TenKhoa) VALUES
('K01', N'Công nghệ thông tin'),
('K02', N'Kinh tế');
GO

-- NGANH (3)
INSERT INTO NGANH (MaNganh, TenNganh, MaKhoa) VALUES
('N01', N'Công nghệ thông tin', 'K01'),
('N02', N'Khoa học máy tính', 'K01'),
('N03', N'Quản trị kinh doanh', 'K02');
GO

-- BO_MON (4)
-- Chưa gán MaTruongBM vì GIANG_VIEN chưa có dữ liệu (tránh lỗi tham chiếu tới dòng chưa tồn tại).
INSERT INTO BO_MON (MaBM, TenBM, MaKhoa, MaTruongBM) VALUES
('BM01', N'Công nghệ phần mềm', 'K01', NULL),
('BM02', N'Mạng máy tính', 'K01', NULL),
('BM03', N'Hệ thống thông tin', 'K01', NULL),
('BM04', N'Kinh doanh quốc tế', 'K02', NULL);
GO

-- GIANG_VIEN (8)
INSERT INTO GIANG_VIEN (MaGV, TenGV, MaBM) VALUES
('GV01', N'Nguyễn Văn A', 'BM01'),
('GV02', N'Trần Thị B',   'BM01'),
('GV03', N'Lê Văn C',     'BM02'),
('GV04', N'Phạm Thị D',   'BM02'),
('GV05', N'Hoàng Văn E',  'BM03'),
('GV06', N'Đỗ Thị F',     'BM03'),
('GV07', N'Vũ Văn G',     'BM04'),
('GV08', N'Bùi Thị H',    'BM04');   -- GV08: cố tình KHÔNG gán làm GVPT lớp nào -> test "GV chưa được phân công" (câu D.19)
GO

-- Bổ sung trưởng bộ môn (ràng buộc B.5: mỗi trưởng BM phải là GV thuộc chính BM đó -> chọn đúng theo MaBM ở trên)
UPDATE BO_MON SET MaTruongBM = 'GV01' WHERE MaBM = 'BM01';
UPDATE BO_MON SET MaTruongBM = 'GV03' WHERE MaBM = 'BM02';
UPDATE BO_MON SET MaTruongBM = 'GV05' WHERE MaBM = 'BM03';
UPDATE BO_MON SET MaTruongBM = 'GV07' WHERE MaBM = 'BM04';
GO

-- LOP_HANH_CHINH (5)
INSERT INTO LOP_HANH_CHINH (MaLop, TenLop, MaNganh) VALUES
('L01', N'CNTT K1', 'N01'),
('L02', N'CNTT K2', 'N01'),
('L03', N'KHMT K1', 'N02'),
('L04', N'QTKD K1', 'N03'),
('L05', N'QTKD K2', 'N03');
GO

-- SINH_VIEN (20)
INSERT INTO SINH_VIEN (MaSV, TenSV, MaLop) VALUES
('SV01', N'Sinh viên 01', 'L01'), ('SV02', N'Sinh viên 02', 'L01'),
('SV03', N'Sinh viên 03', 'L01'), ('SV04', N'Sinh viên 04', 'L01'),
('SV05', N'Sinh viên 05', 'L02'), ('SV06', N'Sinh viên 06', 'L02'),
('SV07', N'Sinh viên 07', 'L02'), ('SV08', N'Sinh viên 08', 'L02'),
('SV09', N'Sinh viên 09', 'L03'), ('SV10', N'Sinh viên 10', 'L03'),
('SV11', N'Sinh viên 11', 'L03'), ('SV12', N'Sinh viên 12', 'L03'),
('SV13', N'Sinh viên 13', 'L04'), ('SV14', N'Sinh viên 14', 'L04'),
('SV15', N'Sinh viên 15', 'L04'), ('SV16', N'Sinh viên 16', 'L04'),
('SV17', N'Sinh viên 17', 'L05'), ('SV18', N'Sinh viên 18', 'L05'),
('SV19', N'Sinh viên 19', 'L05'), ('SV20', N'Sinh viên 20', 'L05');
GO

-- HOC_PHAN (12)
INSERT INTO HOC_PHAN (MaHP, TenHP, SoTinChi) VALUES
('HP01', N'Nhập môn lập trình', 3),
('HP02', N'Cấu trúc dữ liệu và giải thuật', 4),
('HP03', N'Cơ sở dữ liệu', 3),
('HP04', N'Lập trình hướng đối tượng', 4),
('HP05', N'Phân tích thiết kế hệ thống', 3),
('HP06', N'Mạng máy tính', 3),
('HP07', N'Hệ điều hành', 3),
('HP08', N'Lập trình web', 4),
('HP09', N'Toán rời rạc', 2),
('HP10', N'Kinh tế vi mô', 3),
('HP11', N'Quản trị học', 2),
('HP12', N'Đồ án chuyên ngành', 5);
GO

-- CHUONG_TRINH_DAO_TAO
-- 1 học phần (HP01, HP09...) nằm trong chương trình của NHIỀU ngành, đúng như đề mô tả.
INSERT INTO CHUONG_TRINH_DAO_TAO (MaNganh, MaHP, LoaiHP) VALUES
('N01','HP01','BB'), ('N01','HP02','BB'), ('N01','HP03','BB'), ('N01','HP04','BB'),
('N01','HP05','BB'), ('N01','HP06','TC'), ('N01','HP07','BB'), ('N01','HP08','TC'),
('N01','HP09','BB'), ('N01','HP12','BB'),
('N02','HP01','BB'), ('N02','HP02','BB'), ('N02','HP04','BB'), ('N02','HP05','BB'),
('N02','HP07','BB'), ('N02','HP09','BB'), ('N02','HP12','BB'), ('N02','HP03','TC'),
('N03','HP10','BB'), ('N03','HP11','BB'), ('N03','HP09','TC');
GO

-- HOC_PHAN_TIEN_QUYET
-- HP05 có 2 tiên quyết trực tiếp (HP03, HP04) -> test D.21
-- Chuỗi: HP01 -> HP02 -> HP04 -> HP05 -> HP12 (dài 4 mức, >3 theo yêu cầu) -> test D.22
INSERT INTO HOC_PHAN_TIEN_QUYET (MaHP, MaHP_TienQuyet) VALUES
('HP02','HP01'),
('HP03','HP01'),
('HP04','HP02'),
('HP05','HP03'),
('HP05','HP04'),
('HP06','HP01'),
('HP08','HP04'),
('HP12','HP05');
GO

-- LOP_HOC_PHAN (15, trải trên 3 học kỳ)
INSERT INTO LOP_HOC_PHAN (MaLHP, MaHP, MaGVPT, HocKy, NamHoc, PhongHoc, SiSoToiDa) VALUES
('LHP01','HP01','GV01',1,'2024-2025','A101',4),
('LHP02','HP02','GV02',1,'2024-2025','A102',4),
('LHP03','HP03','GV05',1,'2024-2025','A103',4),
('LHP04','HP01','GV01',2,'2024-2025','A101',4),   -- lớp mở lại HP01 để SV10 học lại
('LHP05','HP04','GV02',2,'2024-2025','A104',4),
('LHP06','HP05','GV05',2,'2024-2025','A105',3),   -- sĩ số nhỏ -> sẽ cho đăng ký ĐẦY
('LHP07','HP06','GV03',2,'2024-2025','A106',5),
('LHP08','HP07','GV06',1,'2025-2026','A107',5),
('LHP09','HP08','GV04',1,'2025-2026','A108',5),
('LHP10','HP09','GV01',1,'2025-2026','A109',5),   -- sẽ cho đăng ký ĐẦY
('LHP11','HP10','GV07',1,'2024-2025','B101',6),   -- sẽ cho đăng ký ĐẦY
('LHP12','HP11','GV07',1,'2024-2025','B102',6),
('LHP13','HP12','GV02',1,'2025-2026','A110',3),   -- CỐ TÌNH không cho đăng ký -> test D.18
('LHP14','HP03','GV05',2,'2024-2025','A112',5),   -- lớp mở lại HP03 để SV01 học lại
('LHP15','HP10','GV07',1,'2025-2026','B103',6);
GO

-- DANG_KY (63 lượt)
-- LHP01 (HP01, HK1 2024-2025): SV10 TRƯỢT (TK=2.4) -> học lại ở LHP04
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV01','LHP01','2024-08-15',8,7,8),
('SV02','LHP01','2024-08-15',7,6,7),
('SV03','LHP01','2024-08-15',6,5,5),
('SV10','LHP01','2024-08-15',3,3,2);
GO

-- LHP02 (HP02, HK1 2024-2025)
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV01','LHP02','2024-08-15',8,8,8),
('SV02','LHP02','2024-08-15',7,7,7),
('SV05','LHP02','2024-08-15',6,6,6),
('SV06','LHP02','2024-08-15',5,4,5);
GO

-- LHP03 (HP03, HK1 2024-2025): SV01 TRƯỢT (TK=2.5) -> học lại ở LHP14
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV01','LHP03','2024-08-15',4,3,2),
('SV07','LHP03','2024-08-15',7,6,7),
('SV08','LHP03','2024-08-15',8,7,8),
('SV09','LHP03','2024-08-15',5,5,4);
GO

-- LHP04 (HP01 - lớp học lại, HK2 2024-2025): SV10 học lại và ĐẠT (TK=7.6); SV12 TRƯỢT (TK=3.1)
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV10','LHP04','2025-01-10',7,7,8),
('SV11','LHP04','2025-01-10',6,5,6),
('SV12','LHP04','2025-01-10',4,3,3),
('SV13','LHP04','2025-01-10',8,8,9);
GO

-- LHP05 (HP04, HK2 2024-2025)
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV01','LHP05','2025-01-10',8,8,9),
('SV02','LHP05','2025-01-10',7,6,7),
('SV05','LHP05','2025-01-10',6,5,5),
('SV06','LHP05','2025-01-10',5,4,4);
GO

-- LHP06 (HP05, HK2 2024-2025, sĩ số tối đa 3): đăng ký ĐỦ 3/3 -> LỚP ĐẦY. SV05 TRƯỢT (TK=3.5)
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV01','LHP06','2025-01-10',8,7,8),
('SV02','LHP06','2025-01-10',7,7,7),
('SV05','LHP06','2025-01-10',5,4,3);
GO

-- LHP07 (HP06, HK2 2024-2025): SV15 TRƯỢT (TK=3.4)
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV03','LHP07','2025-01-10',6,6,6),
('SV04','LHP07','2025-01-10',7,7,7),
('SV13','LHP07','2025-01-10',8,7,8),
('SV14','LHP07','2025-01-10',5,5,5),
('SV15','LHP07','2025-01-10',4,4,3);
GO

-- LHP08 (HP07, HK1 2025-2026 - học kỳ đang diễn ra): chỉ có điểm chuyên cần, GK/CK để NULL
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV15','LHP08','2025-08-15',7,NULL,NULL),
('SV16','LHP08','2025-08-15',8,NULL,NULL),
('SV17','LHP08','2025-08-15',6,NULL,NULL),
('SV18','LHP08','2025-08-15',7,NULL,NULL),
('SV19','LHP08','2025-08-15',5,NULL,NULL);
GO

-- LHP09 (HP08, HK1 2025-2026)
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV05','LHP09','2025-08-15',8,NULL,NULL),
('SV06','LHP09','2025-08-15',7,NULL,NULL),
('SV07','LHP09','2025-08-15',6,NULL,NULL),
('SV08','LHP09','2025-08-15',7,NULL,NULL),
('SV09','LHP09','2025-08-15',5,NULL,NULL);
GO

-- LHP10 (HP09, HK1 2025-2026, sĩ số tối đa 5): đăng ký ĐỦ 5/5 -> LỚP ĐẦY
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV01','LHP10','2025-08-15',8,NULL,NULL),
('SV02','LHP10','2025-08-15',7,NULL,NULL),
('SV03','LHP10','2025-08-15',6,NULL,NULL),
('SV04','LHP10','2025-08-15',7,NULL,NULL),
('SV05','LHP10','2025-08-15',8,NULL,NULL);
GO

-- LHP11 (HP10, HK1 2024-2025, sĩ số tối đa 6): đăng ký ĐỦ 6/6 -> LỚP ĐẦY. SV20 TRƯỢT (TK=3.4)
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV16','LHP11','2024-08-15',7,7,7),
('SV17','LHP11','2024-08-15',6,6,6),
('SV18','LHP11','2024-08-15',5,5,5),
('SV19','LHP11','2024-08-15',8,8,8),
('SV20','LHP11','2024-08-15',4,4,3),
('SV14','LHP11','2024-08-15',6,6,5);
GO

-- LHP12 (HP11, HK1 2024-2025)
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV16','LHP12','2024-08-15',7,6,7),
('SV17','LHP12','2024-08-15',8,7,8),
('SV20','LHP12','2024-08-15',5,5,4),
('SV14','LHP12','2024-08-15',6,5,6),
('SV15','LHP12','2024-08-15',7,6,6);
GO

-- LHP13 (HP12, HK1 2025-2026): CỐ TÌNH KHÔNG insert dòng nào ở đây
-- -> test "học phần/lớp học phần đã mở nhưng chưa từng có sinh viên đăng ký" (câu D.18)

-- LHP14 (HP03 - lớp học lại, HK2 2024-2025): SV01 học lại HP03 và ĐẠT (TK=7.6)
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV01','LHP14','2025-01-10',7,7,8),
('SV20','LHP14','2025-01-10',6,6,6),
('SV11','LHP14','2025-01-10',5,4,5);
GO

-- LHP15 (HP10, HK1 2025-2026)
INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy) VALUES
('SV06','LHP15','2025-08-15',7,NULL,NULL),
('SV07','LHP15','2025-08-15',6,NULL,NULL),
('SV08','LHP15','2025-08-15',8,NULL,NULL),
('SV09','LHP15','2025-08-15',5,NULL,NULL),
('SV10','LHP15','2025-08-15',7,NULL,NULL),
('SV02','LHP15','2025-08-15',6,NULL,NULL);
GO

 -- CÂU 8. CỐ Ý VI PHẠM RÀNG BUỘC ĐỂ KIỂM THỬ
-- 8.1 Vi phạm B.1 (CHECK): số tín chỉ ngoài khoảng 1-6
BEGIN TRY
    INSERT INTO HOC_PHAN (MaHP, TenHP, SoTinChi) VALUES ('HPX1', N'Học phần lỗi tín chỉ', 7);
    PRINT N'8.1: KHONG bi chan (SAI, can xem lai)';
END TRY
BEGIN CATCH
    PRINT N'8.1: BI TU CHOI - ' + ERROR_MESSAGE();
END CATCH
GO

-- 8.2 Vi phạm B.2 (CHECK): điểm ngoài khoảng 0-10 -- dùng LHP13 (đang trống chỗ) để không bị lẫn với lỗi sĩ số
BEGIN TRY
    INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy)
    VALUES ('SV01','LHP13','2025-08-20',5,5,15);
    PRINT N'8.2: KHONG bi chan (SAI, can xem lai)';
END TRY
BEGIN CATCH
    PRINT N'8.2: BI TU CHOI - ' + ERROR_MESSAGE();
END CATCH
GO

-- 8.3 Vi phạm PK / B.4: đăng ký lại 1 lớp đã đăng ký -- dùng LHP12 (còn chỗ trống, để chắc chắn
-- lỗi hiện ra là do PK trùng chứ không phải do trigger sĩ số chặn trước)
BEGIN TRY
    INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy)
    VALUES ('SV16','LHP12','2024-08-25',9,9,9);
    PRINT N'8.3: KHONG bi chan (SAI, can xem lai)';
END TRY
BEGIN CATCH
    PRINT N'8.3: BI TU CHOI - ' + ERROR_MESSAGE();
END CATCH
GO

-- 8.4 Vi phạm FK / B.14: MaSV không tồn tại
BEGIN TRY
    INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy)
    VALUES ('SV99','LHP13','2025-08-20',8,8,8);
    PRINT N'8.4: KHONG bi chan (SAI, can xem lai)';
END TRY
BEGIN CATCH
    PRINT N'8.4: BI TU CHOI - ' + ERROR_MESSAGE();
END CATCH
GO

-- 8.5 Vi phạm NOT NULL / B.13: ngày đăng ký để trống
BEGIN TRY
    INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy)
    VALUES ('SV04','LHP13', NULL, 8,8,8);
    PRINT N'8.5: KHONG bi chan (SAI, can xem lai)';
END TRY
BEGIN CATCH
    PRINT N'8.5: BI TU CHOI - ' + ERROR_MESSAGE();
END CATCH
GO

-- 8.6 Vi phạm CHECK / B.9: 1 học phần là tiên quyết của chính nó
BEGIN TRY
    INSERT INTO HOC_PHAN_TIEN_QUYET (MaHP, MaHP_TienQuyet) VALUES ('HP01','HP01');
    PRINT N'8.6: KHONG bi chan (SAI, can xem lai)';
END TRY
BEGIN CATCH
    PRINT N'8.6: BI TU CHOI - ' + ERROR_MESSAGE();
END CATCH
GO

-- 8.7 Vi phạm B.8 (qua TRIGGER): LHP06 đã đầy 3/3 từ Câu 7, đăng ký thêm 1 SV nữa
BEGIN TRY
    INSERT INTO DANG_KY (MaSV, MaLHP, NgayDangKy, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy)
    VALUES ('SV07','LHP06','2025-01-15',8,8,8);
    PRINT N'8.7: KHONG bi chan (SAI, can xem lai)';
END TRY
BEGIN CATCH
    PRINT N'8.7: BI TU CHOI - ' + ERROR_MESSAGE();
END CATCH
GO

-- 8.8 Ràng buộc B.5 (trưởng bộ môn phải thuộc chính BM đó) -- CTDL HIỆN TẠI CHƯA NGĂN ĐƯỢC:
-- FK chỉ kiểm tra MaTruongBM có tồn tại trong GIANG_VIEN, KHÔNG kiểm tra MaBM của GV đó
-- có trùng với bộ môn đang gán hay không -> lệnh dưới đây SẼ CHẠY ĐƯỢC dù sai nghiệp vụ.
UPDATE BO_MON SET MaTruongBM = 'GV07' WHERE MaBM = 'BM01';   -- GV07 thuộc BM04, không phải BM01!
SELECT MaBM, MaTruongBM FROM BO_MON WHERE MaBM = 'BM01';     -- minh chứng: đổi thành công
-- Undo ngay để không ảnh hưởng Phần D. Ràng buộc B.5 sẽ được chặn bằng trigger ở Câu 35.
UPDATE BO_MON SET MaTruongBM = 'GV01' WHERE MaBM = 'BM01';
GO

-- 8.9 Ràng buộc B.10 (tiên quyết không được tạo chu trình) -- CTDL HIỆN TẠI CHƯA NGĂN ĐƯỢC:
-- PK/FK/CHECK chỉ xét được 1 dòng, không duyệt được cả đồ thị tiên quyết
-- -> thêm cạnh HP01 tiên quyết là HP12 sẽ tạo chu trình HP01->HP02->HP04->HP05->HP12->HP01, vẫn insert được.
INSERT INTO HOC_PHAN_TIEN_QUYET (MaHP, MaHP_TienQuyet) VALUES ('HP01','HP12');
SELECT * FROM HOC_PHAN_TIEN_QUYET WHERE MaHP = 'HP01' AND MaHP_TienQuyet = 'HP12'; -- minh chứng: vẫn có dòng này
-- Undo ngay để không ảnh hưởng Phần D. Ràng buộc B.10 sẽ được chặn bằng trigger đệ quy ở Câu 35.
DELETE FROM HOC_PHAN_TIEN_QUYET WHERE MaHP = 'HP01' AND MaHP_TienQuyet = 'HP12';
GO

-- ================= PHẦN 3: Truy vấn (Phần D & E) =================

USE QuanLyDaoTao;
GO

-- Câu D1. Liệt kê sinh viên: mã SV, họ tên, lớp hành chính, ngành
-- Kỹ thuật: INNER JOIN 3 bảng
SELECT
    sv.MaSV,
    sv.TenSV,
    lhc.TenLop,
    n.TenNganh
FROM SINH_VIEN sv
JOIN LOP_HANH_CHINH lhc ON sv.MaLop = lhc.MaLop
JOIN NGANH n             ON lhc.MaNganh = n.MaNganh
ORDER BY sv.MaSV;
GO

-- Câu D2. Liệt kê lớp học phần: mã lớp, tên học phần, học kỳ, năm học, GV phụ trách
-- Kỹ thuật: INNER JOIN
SELECT
    lhp.MaLHP,
    hp.TenHP,
    lhp.HocKy,
    lhp.NamHoc,
    gv.TenGV
FROM LOP_HOC_PHAN lhp
JOIN HOC_PHAN hp     ON lhp.MaHP = hp.MaHP
JOIN GIANG_VIEN gv   ON lhp.MaGVPT = gv.MaGV
ORDER BY lhp.NamHoc, lhp.HocKy, lhp.MaLHP;
GO

-- Câu D3. Đếm số sinh viên đăng ký từng lớp học phần, KỂ CẢ lớp chưa có đăng ký
-- Kỹ thuật: LEFT JOIN (để giữ lại các lớp không có đăng ký) + GROUP BY
SELECT
    lhp.MaLHP,
    lhp.MaHP,
    COUNT(dk.MaSV) AS SoSinhVienDangKy
FROM LOP_HOC_PHAN lhp
LEFT JOIN DANG_KY dk ON lhp.MaLHP = dk.MaLHP
GROUP BY lhp.MaLHP, lhp.MaHP
ORDER BY lhp.MaLHP;
GO

-- Câu D4. Tìm các lớp học phần đã đủ sĩ số
-- Kỹ thuật: JOIN + GROUP BY + HAVING
SELECT
    lhp.MaLHP,
    lhp.SiSoToiDa,
    COUNT(dk.MaSV) AS SiSoHienTai
FROM LOP_HOC_PHAN lhp
JOIN DANG_KY dk ON lhp.MaLHP = dk.MaLHP
GROUP BY lhp.MaLHP, lhp.SiSoToiDa
HAVING COUNT(dk.MaSV) >= lhp.SiSoToiDa;
GO

-- Câu D5. Tìm các lớp học phần còn chỗ và số chỗ còn lại chính xác
-- Kỹ thuật: LEFT JOIN (để không bỏ sót lớp chưa ai đăng ký) + HAVING
SELECT
    lhp.MaLHP,
    lhp.SiSoToiDa,
    COUNT(dk.MaSV)                         AS SiSoHienTai,
    lhp.SiSoToiDa - COUNT(dk.MaSV)          AS SoChoConLai
FROM LOP_HOC_PHAN lhp
LEFT JOIN DANG_KY dk ON lhp.MaLHP = dk.MaLHP
GROUP BY lhp.MaLHP, lhp.SiSoToiDa
HAVING lhp.SiSoToiDa - COUNT(dk.MaSV) > 0
ORDER BY lhp.MaLHP;
GO

-- Câu D6. Tính điểm tổng kết của từng lượt đăng ký theo công thức đã cho
-- Nếu chưa đủ 3 cột điểm thì điểm tổng kết để NULL (chưa tính được)
SELECT
    dk.MaSV,
    dk.MaLHP,
    dk.DiemChuyenCan,
    dk.DiemGiuaKy,
    dk.DiemCuoiKy,
    CASE
        WHEN dk.DiemChuyenCan IS NULL OR dk.DiemGiuaKy IS NULL OR dk.DiemCuoiKy IS NULL THEN NULL
        ELSE ROUND(0.1 * dk.DiemChuyenCan + 0.3 * dk.DiemGiuaKy + 0.6 * dk.DiemCuoiKy, 2)
    END AS DiemTongKet
FROM DANG_KY dk
ORDER BY dk.MaSV, dk.MaLHP;
GO

-- Câu D7. Tìm các sinh viên có ít nhất một lần trượt học phần (đã có đủ điểm và TK < 4)
-- Kỹ thuật: JOIN + WHERE + DISTINCT
SELECT DISTINCT sv.MaSV, sv.TenSV
FROM SINH_VIEN sv
JOIN DANG_KY dk ON sv.MaSV = dk.MaSV
WHERE dk.DiemChuyenCan IS NOT NULL
  AND dk.DiemGiuaKy    IS NOT NULL
  AND dk.DiemCuoiKy    IS NOT NULL
  AND (0.1 * dk.DiemChuyenCan + 0.3 * dk.DiemGiuaKy + 0.6 * dk.DiemCuoiKy) < 4;
GO

-- Câu D8. Sinh viên đã có kết quả học tập nhưng CHƯA TỪNG trượt học phần nào
-- Kỹ thuật: EXISTS (đã có ít nhất 1 lượt đủ điểm) + NOT EXISTS (không có lượt nào trượt)
SELECT sv.MaSV, sv.TenSV
FROM SINH_VIEN sv
WHERE EXISTS (
        SELECT 1 FROM DANG_KY dk
        WHERE dk.MaSV = sv.MaSV
          AND dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
      )
  AND NOT EXISTS (
        SELECT 1 FROM DANG_KY dk
        WHERE dk.MaSV = sv.MaSV
          AND dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
          AND (0.1 * dk.DiemChuyenCan + 0.3 * dk.DiemGiuaKy + 0.6 * dk.DiemCuoiKy) < 4
      );
GO

-- Câu D9. Sinh viên đã học cùng một học phần từ hai lần trở lên (học lại)
-- Kỹ thuật: JOIN sang LOP_HOC_PHAN để quy lớp về học phần + GROUP BY + HAVING
SELECT
    dk.MaSV,
    lhp.MaHP,
    COUNT(*) AS SoLanHoc
FROM DANG_KY dk
JOIN LOP_HOC_PHAN lhp ON dk.MaLHP = lhp.MaLHP
GROUP BY dk.MaSV, lhp.MaHP
HAVING COUNT(*) >= 2;
GO

-- Câu D10. Tìm học phần có tổng số lượt sinh viên đăng ký lớn nhất
-- Kỹ thuật: GROUP BY + TOP 1 WITH TIES (xử lý trường hợp đồng hạng)
SELECT TOP 1 WITH TIES
    lhp.MaHP,
    hp.TenHP,
    COUNT(*) AS TongLuotDangKy
FROM DANG_KY dk
JOIN LOP_HOC_PHAN lhp ON dk.MaLHP = lhp.MaLHP
JOIN HOC_PHAN hp       ON lhp.MaHP = hp.MaHP
GROUP BY lhp.MaHP, hp.TenHP
ORDER BY COUNT(*) DESC;
GO

-- Câu D11. Tìm giảng viên phụ trách nhiều lớp học phần nhất
SELECT TOP 1 WITH TIES
    gv.MaGV, gv.TenGV,
    COUNT(*) AS SoLopPhuTrach
FROM LOP_HOC_PHAN lhp
JOIN GIANG_VIEN gv ON lhp.MaGVPT = gv.MaGV
GROUP BY gv.MaGV, gv.TenGV
ORDER BY COUNT(*) DESC;
GO

-- Câu D12. Tìm sinh viên có GPA tích lũy cao nhất toàn trường
-- Kỹ thuật: CTE 2 tầng (DiemDayDu -> BestAttempt: mỗi HP chỉ lấy lần TK cao nhất)
WITH DiemDayDu AS (
    SELECT dk.MaSV, lhp.MaHP, hp.SoTinChi,
           (0.1 * dk.DiemChuyenCan + 0.3 * dk.DiemGiuaKy + 0.6 * dk.DiemCuoiKy) AS DiemTongKet
    FROM DANG_KY dk
    JOIN LOP_HOC_PHAN lhp ON dk.MaLHP = lhp.MaLHP
    JOIN HOC_PHAN hp      ON lhp.MaHP = hp.MaHP
    WHERE dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
),
BestAttempt AS (
    SELECT MaSV, MaHP, SoTinChi, MAX(DiemTongKet) AS DiemTongKetCaoNhat
    FROM DiemDayDu
    GROUP BY MaSV, MaHP, SoTinChi
),
GPA_SV AS (
    SELECT MaSV,
           SUM(DiemTongKetCaoNhat * SoTinChi) / SUM(SoTinChi) AS GPA
    FROM BestAttempt
    GROUP BY MaSV
)
SELECT TOP 1 WITH TIES sv.MaSV, sv.TenSV, g.GPA
FROM GPA_SV g
JOIN SINH_VIEN sv ON sv.MaSV = g.MaSV
ORDER BY g.GPA DESC;
GO

-- Câu D13. Sinh viên có GPA cao nhất trong TỪNG lớp hành chính (đồng hạng trả về tất cả)
-- Kỹ thuật: CTE tính GPA + RANK() OVER (PARTITION BY lớp hành chính)
WITH DiemDayDu AS (
    SELECT dk.MaSV, lhp.MaHP, hp.SoTinChi,
           (0.1 * dk.DiemChuyenCan + 0.3 * dk.DiemGiuaKy + 0.6 * dk.DiemCuoiKy) AS DiemTongKet
    FROM DANG_KY dk
    JOIN LOP_HOC_PHAN lhp ON dk.MaLHP = lhp.MaLHP
    JOIN HOC_PHAN hp      ON lhp.MaHP = hp.MaHP
    WHERE dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
),
BestAttempt AS (
    SELECT MaSV, MaHP, SoTinChi, MAX(DiemTongKet) AS DiemTongKetCaoNhat
    FROM DiemDayDu
    GROUP BY MaSV, MaHP, SoTinChi
),
GPA_SV AS (
    SELECT MaSV, SUM(DiemTongKetCaoNhat * SoTinChi) / SUM(SoTinChi) AS GPA
    FROM BestAttempt
    GROUP BY MaSV
),
XepHang AS (
    SELECT sv.MaSV, sv.TenSV, sv.MaLop, g.GPA,
           RANK() OVER (PARTITION BY sv.MaLop ORDER BY g.GPA DESC) AS Hang
    FROM GPA_SV g
    JOIN SINH_VIEN sv ON sv.MaSV = g.MaSV
)
SELECT MaLop, MaSV, TenSV, GPA
FROM XepHang
WHERE Hang = 1
ORDER BY MaLop;
GO

-- Câu D14. Với mỗi lớp học phần, tìm sinh viên có điểm tổng kết cao hơn điểm TB của chính lớp đó
-- Kỹ thuật: subquery tương quan (correlated subquery) tính điểm TB của lớp
SELECT
    dk.MaLHP, dk.MaSV,
    (0.1 * dk.DiemChuyenCan + 0.3 * dk.DiemGiuaKy + 0.6 * dk.DiemCuoiKy) AS DiemTongKet
FROM DANG_KY dk
WHERE dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
  AND (0.1 * dk.DiemChuyenCan + 0.3 * dk.DiemGiuaKy + 0.6 * dk.DiemCuoiKy) >
      (
        SELECT AVG(0.1 * dk2.DiemChuyenCan + 0.3 * dk2.DiemGiuaKy + 0.6 * dk2.DiemCuoiKy)
        FROM DANG_KY dk2
        WHERE dk2.MaLHP = dk.MaLHP
          AND dk2.DiemChuyenCan IS NOT NULL AND dk2.DiemGiuaKy IS NOT NULL AND dk2.DiemCuoiKy IS NOT NULL
      )
ORDER BY dk.MaLHP, DiemTongKet DESC;
GO

-- Câu D15. Sinh viên đạt điểm tổng kết cao nhất trong từng lớp học phần (xử lý đồng điểm)
-- Kỹ thuật: RANK() OVER (PARTITION BY MaLHP ORDER BY DiemTongKet DESC)
WITH DiemLop AS (
    SELECT dk.MaLHP, dk.MaSV,
           (0.1 * dk.DiemChuyenCan + 0.3 * dk.DiemGiuaKy + 0.6 * dk.DiemCuoiKy) AS DiemTongKet
    FROM DANG_KY dk
    WHERE dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
),
XepHang AS (
    SELECT *, RANK() OVER (PARTITION BY MaLHP ORDER BY DiemTongKet DESC) AS Hang
    FROM DiemLop
)
SELECT MaLHP, MaSV, DiemTongKet
FROM XepHang
WHERE Hang = 1
ORDER BY MaLHP;
GO

-- Câu D16. Với một học kỳ/năm học chỉ định (@HocKy, @NamHoc), tìm SV đăng ký tổng tín chỉ lớn nhất
-- Kỹ thuật: biến, JOIN, GROUP BY, TOP 1 WITH TIES
DECLARE @HocKy INT = 1;
DECLARE @NamHoc VARCHAR(9) = '2024-2025';

SELECT TOP 1 WITH TIES
    dk.MaSV,
    SUM(hp.SoTinChi) AS TongTinChiDangKy
FROM DANG_KY dk
JOIN LOP_HOC_PHAN lhp ON dk.MaLHP = lhp.MaLHP
JOIN HOC_PHAN hp      ON lhp.MaHP = hp.MaHP
WHERE lhp.HocKy = @HocKy AND lhp.NamHoc = @NamHoc
GROUP BY dk.MaSV
ORDER BY SUM(hp.SoTinChi) DESC;
GO

-- Câu D17. Với một học kỳ/năm học chỉ định, tìm SV đăng ký TẤT CẢ các học phần có mở lớp trong kỳ đó
-- (một HP mở nhiều lớp thì chỉ cần đăng ký 1 trong các lớp đó)
-- Kỹ thuật: NOT EXISTS lồng nhau ("không tồn tại HP nào mà SV chưa đăng ký")
DECLARE @HocKy2 INT = 1;
DECLARE @NamHoc2 VARCHAR(9) = '2025-2026';

SELECT sv.MaSV, sv.TenSV
FROM SINH_VIEN sv
WHERE NOT EXISTS (
    SELECT 1
    FROM LOP_HOC_PHAN lhp
    WHERE lhp.HocKy = @HocKy2 AND lhp.NamHoc = @NamHoc2
      AND NOT EXISTS (
            SELECT 1
            FROM DANG_KY dk
            JOIN LOP_HOC_PHAN lhp2 ON dk.MaLHP = lhp2.MaLHP
            WHERE dk.MaSV = sv.MaSV
              AND lhp2.MaHP = lhp.MaHP
              AND lhp2.HocKy = @HocKy2 AND lhp2.NamHoc = @NamHoc2
      )
);
GO

-- Câu D18. Tìm các học phần đã từng được mở lớp nhưng CHƯA TỪNG có sinh viên đăng ký
-- Kỹ thuật: EXISTS (đã có lớp mở) + NOT EXISTS (không có đăng ký ở bất kỳ lớp nào của HP đó)
SELECT hp.MaHP, hp.TenHP
FROM HOC_PHAN hp
WHERE EXISTS (SELECT 1 FROM LOP_HOC_PHAN lhp WHERE lhp.MaHP = hp.MaHP)
  AND NOT EXISTS (
        SELECT 1
        FROM DANG_KY dk
        JOIN LOP_HOC_PHAN lhp ON dk.MaLHP = lhp.MaLHP
        WHERE lhp.MaHP = hp.MaHP
      );
GO

-- Câu D19. Tìm giảng viên chưa từng được phân công phụ trách lớp học phần nào
-- Kỹ thuật: NOT EXISTS
SELECT gv.MaGV, gv.TenGV
FROM GIANG_VIEN gv
WHERE NOT EXISTS (SELECT 1 FROM LOP_HOC_PHAN lhp WHERE lhp.MaGVPT = gv.MaGV);
GO

-- Câu D20. Tìm học phần KHÔNG yêu cầu bất kỳ học phần tiên quyết trực tiếp nào
-- Kỹ thuật: NOT EXISTS
SELECT hp.MaHP, hp.TenHP
FROM HOC_PHAN hp
WHERE NOT EXISTS (
    SELECT 1 FROM HOC_PHAN_TIEN_QUYET t WHERE t.MaHP = hp.MaHP
);
GO

-- Câu D21. Tìm học phần có ít nhất 2 học phần tiên quyết trực tiếp
-- Kỹ thuật: GROUP BY + HAVING
SELECT hp.MaHP, hp.TenHP, COUNT(*) AS SoTienQuyetTrucTiep
FROM HOC_PHAN_TIEN_QUYET t
JOIN HOC_PHAN hp ON hp.MaHP = t.MaHP
GROUP BY hp.MaHP, hp.TenHP
HAVING COUNT(*) >= 2;
GO

-- Câu D22. Với mã học phần @MaHP, tìm toàn bộ học phần tiên quyết TRỰC TIẾP và GIÁN TIẾP,
-- hiển thị mức (Level) của quan hệ tiên quyết
-- Kỹ thuật: Recursive CTE
DECLARE @MaHP VARCHAR(10) = 'HP12';

WITH TienQuyet AS (
    -- Level 1: các tiên quyết trực tiếp của @MaHP
    SELECT MaHP_TienQuyet AS MaHP_KetQua, 1 AS Level_
    FROM HOC_PHAN_TIEN_QUYET
    WHERE MaHP = @MaHP

    UNION ALL

    -- Đệ quy: tiên quyết của các tiên quyết đã tìm được (gián tiếp)
    SELECT t.MaHP_TienQuyet, tq.Level_ + 1
    FROM HOC_PHAN_TIEN_QUYET t
    JOIN TienQuyet tq ON t.MaHP = tq.MaHP_KetQua
)
SELECT tq.MaHP_KetQua AS MaHP, hp.TenHP, MIN(tq.Level_) AS Level_
FROM TienQuyet tq
JOIN HOC_PHAN hp ON hp.MaHP = tq.MaHP_KetQua
GROUP BY tq.MaHP_KetQua, hp.TenHP
ORDER BY Level_;
GO

-- Câu D23. Tìm học phần đang là điều kiện tiên quyết trực tiếp của nhiều học phần khác nhất
-- Kỹ thuật: GROUP BY + TOP 1 WITH TIES
SELECT TOP 1 WITH TIES
    hp.MaHP, hp.TenHP,
    COUNT(*) AS SoHocPhanPhuThuoc
FROM HOC_PHAN_TIEN_QUYET t
JOIN HOC_PHAN hp ON hp.MaHP = t.MaHP_TienQuyet
GROUP BY hp.MaHP, hp.TenHP
ORDER BY COUNT(*) DESC;
GO

-- Câu D24. Xếp hạng sinh viên theo GPA tích lũy trong từng ngành bằng DENSE_RANK()
-- Kỹ thuật: CTE tính GPA + DENSE_RANK() OVER (PARTITION BY ngành)
WITH DiemDayDu AS (
    SELECT dk.MaSV, lhp.MaHP, hp.SoTinChi,
           (0.1 * dk.DiemChuyenCan + 0.3 * dk.DiemGiuaKy + 0.6 * dk.DiemCuoiKy) AS DiemTongKet
    FROM DANG_KY dk
    JOIN LOP_HOC_PHAN lhp ON dk.MaLHP = lhp.MaLHP
    JOIN HOC_PHAN hp      ON lhp.MaHP = hp.MaHP
    WHERE dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
),
BestAttempt AS (
    SELECT MaSV, MaHP, SoTinChi, MAX(DiemTongKet) AS DiemTongKetCaoNhat
    FROM DiemDayDu
    GROUP BY MaSV, MaHP, SoTinChi
),
GPA_SV AS (
    SELECT MaSV, SUM(DiemTongKetCaoNhat * SoTinChi) / SUM(SoTinChi) AS GPA
    FROM BestAttempt
    GROUP BY MaSV
)
SELECT
    n.MaNganh, n.TenNganh,
    sv.MaSV, sv.TenSV, g.GPA,
    DENSE_RANK() OVER (PARTITION BY n.MaNganh ORDER BY g.GPA DESC) AS XepHang
FROM GPA_SV g
JOIN SINH_VIEN sv      ON sv.MaSV = g.MaSV
JOIN LOP_HANH_CHINH lhc ON sv.MaLop = lhc.MaLop
JOIN NGANH n            ON lhc.MaNganh = n.MaNganh
ORDER BY n.MaNganh, XepHang;
GO

-- Câu D25. Top 3 sinh viên có GPA cao nhất của mỗi ngành (đồng hạng vẫn được liệt kê đủ)
-- Kỹ thuật: DENSE_RANK() rồi lọc <= 3 (đồng hạng sẽ không bị "cắt cụt")
WITH DiemDayDu AS (
    SELECT dk.MaSV, lhp.MaHP, hp.SoTinChi,
           (0.1 * dk.DiemChuyenCan + 0.3 * dk.DiemGiuaKy + 0.6 * dk.DiemCuoiKy) AS DiemTongKet
    FROM DANG_KY dk
    JOIN LOP_HOC_PHAN lhp ON dk.MaLHP = lhp.MaLHP
    JOIN HOC_PHAN hp      ON lhp.MaHP = hp.MaHP
    WHERE dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
),
BestAttempt AS (
    SELECT MaSV, MaHP, SoTinChi, MAX(DiemTongKet) AS DiemTongKetCaoNhat
    FROM DiemDayDu
    GROUP BY MaSV, MaHP, SoTinChi
),
GPA_SV AS (
    SELECT MaSV, SUM(DiemTongKetCaoNhat * SoTinChi) / SUM(SoTinChi) AS GPA
    FROM BestAttempt
    GROUP BY MaSV
),
XepHang AS (
    SELECT
        n.MaNganh, n.TenNganh, sv.MaSV, sv.TenSV, g.GPA,
        DENSE_RANK() OVER (PARTITION BY n.MaNganh ORDER BY g.GPA DESC) AS Hang
    FROM GPA_SV g
    JOIN SINH_VIEN sv       ON sv.MaSV = g.MaSV
    JOIN LOP_HANH_CHINH lhc ON sv.MaLop = lhc.MaLop
    JOIN NGANH n            ON lhc.MaNganh = n.MaNganh
)
SELECT MaNganh, TenNganh, MaSV, TenSV, GPA, Hang
FROM XepHang
WHERE Hang <= 3
ORDER BY MaNganh, Hang;
GO

-- Câu D26. Trong các lớp đã có điểm ĐẦY ĐỦ (mọi lượt đăng ký của lớp đều đủ 3 cột điểm),
-- tìm lớp học phần có tỷ lệ lượt sinh viên trượt cao nhất
-- Tỷ lệ trượt = (số lượt TK < 4) / (tổng số lượt đã có đủ 3 thành phần điểm)
WITH ThongKeLop AS (
    SELECT
        lhp.MaLHP,
        COUNT(*) AS TongLuotDangKy,
        SUM(CASE WHEN dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
                 THEN 1 ELSE 0 END) AS SoLuotDuDiem,
        SUM(CASE WHEN dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
                      AND (0.1*dk.DiemChuyenCan + 0.3*dk.DiemGiuaKy + 0.6*dk.DiemCuoiKy) < 4
                 THEN 1 ELSE 0 END) AS SoLuotTruot
    FROM LOP_HOC_PHAN lhp
    JOIN DANG_KY dk ON lhp.MaLHP = dk.MaLHP
    GROUP BY lhp.MaLHP
)
SELECT TOP 1 WITH TIES
    MaLHP, SoLuotTruot, SoLuotDuDiem,
    CAST(SoLuotTruot AS FLOAT) / SoLuotDuDiem AS TyLeTruot
FROM ThongKeLop
WHERE TongLuotDangKy = SoLuotDuDiem   -- lớp đã có điểm đầy đủ cho toàn bộ đăng ký
  AND SoLuotDuDiem > 0
ORDER BY TyLeTruot DESC;
GO

-- Câu D27. Điểm tổng kết trung bình của sinh viên theo TỪNG giảng viên phụ trách,
-- tìm giảng viên có giá trị trung bình cao nhất (chỉ xét lượt đăng ký đã có đủ điểm)
WITH DiemTheoGV AS (
    SELECT lhp.MaGVPT,
           (0.1 * dk.DiemChuyenCan + 0.3 * dk.DiemGiuaKy + 0.6 * dk.DiemCuoiKy) AS DiemTongKet
    FROM DANG_KY dk
    JOIN LOP_HOC_PHAN lhp ON dk.MaLHP = lhp.MaLHP
    WHERE dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
)
SELECT TOP 1 WITH TIES
    gv.MaGV, gv.TenGV,
    AVG(d.DiemTongKet) AS DiemTongKetTrungBinh
FROM DiemTheoGV d
JOIN GIANG_VIEN gv ON gv.MaGV = d.MaGVPT
GROUP BY gv.MaGV, gv.TenGV
ORDER BY AVG(d.DiemTongKet) DESC;
GO

-- Câu D28. Tính GPA từng học kỳ của từng sinh viên; tìm sinh viên có GPA học kỳ
-- TĂNG NGHIÊM NGẶT qua ít nhất 3 học kỳ LIÊN TIẾP (trong số các học kỳ SV có kết quả)
-- Kỹ thuật: CTE + LAG() + kỹ thuật "nhóm dãy liên tục" bằng SUM(cờ ngắt) OVER (...)
WITH GPAHocKy AS (
    SELECT
        dk.MaSV, lhp.NamHoc, lhp.HocKy,
        -- Khóa sắp xếp thời gian: năm bắt đầu * 10 + học kỳ, để sắp đúng thứ tự thời gian
        CAST(LEFT(lhp.NamHoc, 4) AS INT) * 10 + lhp.HocKy AS ThuTuThoiGian,
        SUM((0.1*dk.DiemChuyenCan + 0.3*dk.DiemGiuaKy + 0.6*dk.DiemCuoiKy) * hp.SoTinChi)
            / SUM(hp.SoTinChi) AS GPA_HocKy
    FROM DANG_KY dk
    JOIN LOP_HOC_PHAN lhp ON dk.MaLHP = lhp.MaLHP
    JOIN HOC_PHAN hp      ON lhp.MaHP = hp.MaHP
    WHERE dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
    GROUP BY dk.MaSV, lhp.NamHoc, lhp.HocKy
),
CoDauNgat AS (
    SELECT *,
        LAG(GPA_HocKy) OVER (PARTITION BY MaSV ORDER BY ThuTuThoiGian) AS GPA_KyTruoc,
        ROW_NUMBER()   OVER (PARTITION BY MaSV ORDER BY ThuTuThoiGian) AS ThuTu
    FROM GPAHocKy
),
GanNhom AS (
    SELECT *,
        CASE WHEN GPA_KyTruoc IS NOT NULL AND GPA_HocKy > GPA_KyTruoc THEN 0 ELSE 1 END AS CoNgat
    FROM CoDauNgat
),
NhomDay AS (
    SELECT *,
        SUM(CoNgat) OVER (PARTITION BY MaSV ORDER BY ThuTu ROWS UNBOUNDED PRECEDING) AS NhomID
    FROM GanNhom
)
SELECT
    sv.MaSV, sv.TenSV,
    MIN(n.NamHoc) AS TuHocKy, MIN(n.HocKy) AS HocKyBatDau,
    COUNT(*) AS SoHocKyTangLienTiep
FROM NhomDay n
JOIN SINH_VIEN sv ON sv.MaSV = n.MaSV
GROUP BY n.MaSV, sv.MaSV, sv.TenSV, n.NhomID
HAVING COUNT(*) >= 3
ORDER BY sv.MaSV;
GO

-- Câu D29. Tính số tín chỉ tích lũy của từng sinh viên; tìm SV có số tín chỉ tích lũy lớn nhất
-- Một học phần chỉ tính tín chỉ 1 lần và chỉ khi ĐẠT (lấy lần điểm cao nhất)
WITH DiemDayDu AS (
    SELECT dk.MaSV, lhp.MaHP, hp.SoTinChi,
           (0.1 * dk.DiemChuyenCan + 0.3 * dk.DiemGiuaKy + 0.6 * dk.DiemCuoiKy) AS DiemTongKet
    FROM DANG_KY dk
    JOIN LOP_HOC_PHAN lhp ON dk.MaLHP = lhp.MaLHP
    JOIN HOC_PHAN hp      ON lhp.MaHP = hp.MaHP
    WHERE dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
),
BestAttempt AS (
    SELECT MaSV, MaHP, SoTinChi, MAX(DiemTongKet) AS DiemTongKetCaoNhat
    FROM DiemDayDu
    GROUP BY MaSV, MaHP, SoTinChi
),
TinChiTichLuy AS (
    SELECT MaSV, SUM(SoTinChi) AS TongTinChiTichLuy
    FROM BestAttempt
    WHERE DiemTongKetCaoNhat >= 4
    GROUP BY MaSV
)
SELECT TOP 1 WITH TIES sv.MaSV, sv.TenSV, t.TongTinChiTichLuy
FROM TinChiTichLuy t
JOIN SINH_VIEN sv ON sv.MaSV = t.MaSV
ORDER BY t.TongTinChiTichLuy DESC;
GO

-- Câu D30. Tìm sinh viên đã ĐẠT TẤT CẢ các học phần BẮT BUỘC trong chương trình đào tạo
-- của ngành mà sinh viên đang theo học
-- Kỹ thuật: NOT EXISTS (không tồn tại HP bắt buộc nào mà SV chưa đạt)
SELECT sv.MaSV, sv.TenSV
FROM SINH_VIEN sv
JOIN LOP_HANH_CHINH lhc ON sv.MaLop = lhc.MaLop
WHERE NOT EXISTS (
    SELECT 1
    FROM CHUONG_TRINH_DAO_TAO ctdt
    WHERE ctdt.MaNganh = lhc.MaNganh
      AND ctdt.LoaiHP = 'BB'
      AND NOT EXISTS (
            SELECT 1
            FROM DANG_KY dk
            JOIN LOP_HOC_PHAN lhp2 ON dk.MaLHP = lhp2.MaLHP
            WHERE dk.MaSV = sv.MaSV
              AND lhp2.MaHP = ctdt.MaHP
              AND dk.DiemChuyenCan IS NOT NULL AND dk.DiemGiuaKy IS NOT NULL AND dk.DiemCuoiKy IS NOT NULL
              AND (0.1*dk.DiemChuyenCan + 0.3*dk.DiemGiuaKy + 0.6*dk.DiemCuoiKy) >= 4
      )
);
GO
