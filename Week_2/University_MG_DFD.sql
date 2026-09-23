CREATE TABLE "khoa" (
  "ma_khoa" varchar PRIMARY KEY,
  "ten_khoa" varchar NOT NULL
);

CREATE TABLE "nganh" (
  "ma_nganh" varchar PRIMARY KEY,
  "ten_nganh" varchar NOT NULL,
  "ma_khoa" varchar NOT NULL
);

CREATE TABLE "lop_hanh_chinh" (
  "ma_lop" varchar PRIMARY KEY,
  "ten_lop" varchar NOT NULL,
  "ma_nganh" varchar NOT NULL
);

CREATE TABLE "sinh_vien" (
  "ma_sv" varchar PRIMARY KEY,
  "ten_sv" varchar NOT NULL,
  "ma_lop" varchar NOT NULL
);

CREATE TABLE "bo_mon" (
  "ma_bm" varchar PRIMARY KEY,
  "ten_bm" varchar NOT NULL,
  "ma_khoa" varchar NOT NULL,
  "ma_truong_bm" varchar UNIQUE NOT NULL
);

CREATE TABLE "giang_vien" (
  "ma_gv" varchar PRIMARY KEY,
  "ten_gv" varchar NOT NULL,
  "ma_bm" varchar NOT NULL
);

CREATE TABLE "hoc_phan" (
  "ma_hp" varchar PRIMARY KEY,
  "ten_hp" varchar NOT NULL,
  "so_tin_chi" int NOT NULL
);

CREATE TABLE "chuong_trinh_dao_tao" (
  "ma_nganh" varchar NOT NULL,
  "ma_hp" varchar NOT NULL,
  "loai_hp" varchar NOT NULL,
  PRIMARY KEY ("ma_nganh", "ma_hp")
);

CREATE TABLE "hoc_phan_tien_quyet" (
  "ma_hp" varchar NOT NULL,
  "ma_hp_tien_quyet" varchar NOT NULL,
  PRIMARY KEY ("ma_hp", "ma_hp_tien_quyet")
);

CREATE TABLE "lop_hoc_phan" (
  "ma_lhp" varchar PRIMARY KEY,
  "ma_hp" varchar NOT NULL,
  "ma_gvpt" varchar NOT NULL,
  "hoc_ky" int NOT NULL,
  "nam_hoc" int NOT NULL,
  "phong_hoc" varchar,
  "si_so_toi_da" int NOT NULL
);

CREATE TABLE "dang_ky" (
  "ma_sv" varchar NOT NULL,
  "ma_lhp" varchar NOT NULL,
  "ngay_dang_ky" date NOT NULL,
  "diem_chuyen_can" decimal(4,2),
  "diem_gk" decimal(4,2),
  "diem_cuoi_ki" decimal(4,2),
  PRIMARY KEY ("ma_sv", "ma_lhp")
);

COMMENT ON COLUMN "bo_mon"."ma_truong_bm" IS 'FK vòng với giang_vien.ma_gv - kiểm tra thêm bằng trigger';

COMMENT ON COLUMN "hoc_phan"."so_tin_chi" IS 'CHECK 1 <= so_tin_chi <= 6';

COMMENT ON COLUMN "chuong_trinh_dao_tao"."loai_hp" IS 'CHECK loai_hp IN (BB, TC)';

COMMENT ON COLUMN "hoc_phan_tien_quyet"."ma_hp_tien_quyet" IS 'CHECK ma_hp <> ma_hp_tien_quyet; không tạo chu trình -> trigger';

COMMENT ON COLUMN "lop_hoc_phan"."si_so_toi_da" IS 'CHECK si_so_toi_da > 0';

COMMENT ON COLUMN "dang_ky"."ngay_dang_ky" IS 'phải nằm trong hoc_ky/nam_hoc của LHP -> trigger';

COMMENT ON COLUMN "dang_ky"."diem_chuyen_can" IS 'NULL nếu chưa có; CHECK 0-10';

COMMENT ON COLUMN "dang_ky"."diem_gk" IS 'NULL nếu chưa có; CHECK 0-10';

COMMENT ON COLUMN "dang_ky"."diem_cuoi_ki" IS 'NULL nếu chưa có; CHECK 0-10';

ALTER TABLE "nganh" ADD FOREIGN KEY ("ma_khoa") REFERENCES "khoa" ("ma_khoa") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "lop_hanh_chinh" ADD FOREIGN KEY ("ma_nganh") REFERENCES "nganh" ("ma_nganh") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "sinh_vien" ADD FOREIGN KEY ("ma_lop") REFERENCES "lop_hanh_chinh" ("ma_lop") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "bo_mon" ADD FOREIGN KEY ("ma_khoa") REFERENCES "khoa" ("ma_khoa") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "giang_vien" ADD FOREIGN KEY ("ma_gv") REFERENCES "bo_mon" ("ma_truong_bm") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "giang_vien" ADD FOREIGN KEY ("ma_bm") REFERENCES "bo_mon" ("ma_bm") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "chuong_trinh_dao_tao" ADD FOREIGN KEY ("ma_nganh") REFERENCES "nganh" ("ma_nganh") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "chuong_trinh_dao_tao" ADD FOREIGN KEY ("ma_hp") REFERENCES "hoc_phan" ("ma_hp") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hoc_phan_tien_quyet" ADD FOREIGN KEY ("ma_hp") REFERENCES "hoc_phan" ("ma_hp") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hoc_phan_tien_quyet" ADD FOREIGN KEY ("ma_hp_tien_quyet") REFERENCES "hoc_phan" ("ma_hp") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "lop_hoc_phan" ADD FOREIGN KEY ("ma_hp") REFERENCES "hoc_phan" ("ma_hp") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "lop_hoc_phan" ADD FOREIGN KEY ("ma_gvpt") REFERENCES "giang_vien" ("ma_gv") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "dang_ky" ADD FOREIGN KEY ("ma_sv") REFERENCES "sinh_vien" ("ma_sv") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "dang_ky" ADD FOREIGN KEY ("ma_lhp") REFERENCES "lop_hoc_phan" ("ma_lhp") DEFERRABLE INITIALLY IMMEDIATE;
