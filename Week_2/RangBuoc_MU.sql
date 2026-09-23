
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