
CREATE DATABASE Project_k;
GO


USE Project_k;
GO

-- Tạo bảng Agent
CREATE TABLE Device (
    device_id INT PRIMARY KEY ,
    device_name VARCHAR(255) NOT NULL,
	device_ip VARCHAR(50) NOT NULL,
	device_port VARCHAR(50) NOT NULL,
    device_mac VARCHAR(50) NOT NULL UNIQUE,
);
-- Tạo bảng Quyen
CREATE TABLE Quyen (
    quyen_id INT PRIMARY KEY,
    quyen_name VARCHAR(50) NOT NULL
);
-- Tạo bảng Nhom
CREATE TABLE Nhom (
    nhom_id INT PRIMARY KEY,
    nhom_name VARCHAR(255) NOT NULL,
	quyen_id INT,
	FOREIGN KEY (quyen_id) REFERENCES Quyen(quyen_id)
);

-- Tạo bảng Users
CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    nhom_id INT,
	device_id Int,
    FOREIGN KEY (nhom_id) REFERENCES Nhom(nhom_id),
	FOREIGN KEY (device_id) REFERENCES Device(device_id),
);

-- Tạo bảng ListWeb
CREATE TABLE ListWeb (
    web_id INT PRIMARY KEY,
    web_name VARCHAR(255) NOT NULL,
    url VARCHAR(255),
    web_description TEXT
);


-- Tạo bảng Thongke
CREATE TABLE Log (
    access_id INT PRIMARY KEY,
    device_id INT,
    web_id INT,
    access_date DATETIME,
    num_connections INT DEFAULT 0,
    FOREIGN KEY (device_id) REFERENCES Device(device_id),
    FOREIGN KEY (web_id) REFERENCES ListWeb(web_id)
);
-- Tạo bảng DeletedDevice để lưu thông tin về các thiết bị bị xóa
CREATE TABLE DeletedDevice (
    deleted_device_id INT PRIMARY KEY,
    device_id INT NOT NULL,
    deleted_by_user_id INT,
    deleted_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (device_id) REFERENCES Device(device_id),
    FOREIGN KEY (deleted_by_user_id) REFERENCES Users(user_id)
);

-- Tạo bảng BangTruyVan
CREATE TABLE Query (
    Query_id INT PRIMARY KEY,
    user_id INT,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    action_time DATETIME DEFAULT GETDATE(),
    previous_data NVARCHAR(MAX) NULL,
	FOREIGN KEY (user_id) REFERENCES Users(user_id),
);


go
-- Tạo một stored procedure để thực hiện các bước cập nhật num_connections
CREATE PROCEDURE UpdateNumConnectionsForWebAccess
    @device_id INT,
    @web_id INT
AS
BEGIN
    -- Kiểm tra xem có kết nối giữa user_id và web_id trong ListWeb hay không
    IF EXISTS (
        SELECT 1
        FROM ListWeb
        WHERE web_id = @web_id
    )
    BEGIN
        -- Kiểm tra xem user_id đã truy cập vào web_id chưa trong Thongke
        IF EXISTS (
            SELECT 1
            FROM Log
            WHERE device_id = @device_id
              AND web_id = @web_id
        )
        BEGIN
            -- Nếu đã có thì cập nhật num_connections lên 1
            UPDATE Log
            SET num_connections = num_connections + 1
            WHERE device_id = @device_id
              AND web_id = @web_id;
        END
        ELSE
        BEGIN
            -- Nếu chưa có thì chèn mới một bản ghi vào Thongke
            INSERT INTO Log (device_id, web_id, access_date, num_connections)
            VALUES (@device_id, @web_id, GETDATE(), 1);
        END
    END
END;
-- Trigger xoá từ bảng User
go
CREATE TRIGGER trg_DeleteUser
ON Users
AFTER DELETE
AS
BEGIN
    DECLARE @deleted_user_id INT;
    SELECT @deleted_user_id = user_id FROM deleted;

    INSERT INTO Query (user_id, table_name, record_id, action_type, action_time, previous_data)
    VALUES (USER_ID(), 'Users', @deleted_user_id, 'Xoá', GETDATE(), 'Dữ liệu trước khi xoá');

END;
-- Trigger xoá từ bảng ListWeb
go
CREATE TRIGGER trg_DeleteListWeb
ON ListWeb
AFTER DELETE
AS
BEGIN
    DECLARE @deleted_web_id INT;
    -- Chỉ lấy giá trị của cột web_id từ bảng deleted
    SELECT @deleted_web_id = web_id FROM deleted;

    -- Sau đó sử dụng biến @deleted_web_id trong câu INSERT vào bảng Truy_van
    INSERT INTO Query (user_id, table_name, record_id, action_type, action_time, previous_data)
    VALUES (USER_ID(), 'ListWeb', @deleted_web_id, 'Xoá', GETDATE(), 'Dữ liệu trước khi xoá');

END;

go
-- Trigger xoá từ bảng Thongke
CREATE TRIGGER trg_DeleteThongke
ON Log
AFTER DELETE
AS
BEGIN
    DECLARE @deleted_access_id INT;
    SELECT @deleted_access_id = access_id FROM deleted;

    INSERT INTO Query (user_id, table_name, record_id, action_type, action_time, previous_data)
    VALUES (USER_ID(), 'Thongke', @deleted_access_id, 'Xoá', GETDATE(), 'Dữ liệu trước khi xoá');
END;

go
-- Trigger xoá từ bảng Quyen
CREATE TRIGGER trg_DeleteQuyen
ON Quyen
AFTER DELETE
AS
BEGIN
    DECLARE @deleted_quyen_id INT;
    SELECT @deleted_quyen_id = quyen_id FROM deleted;

    INSERT INTO Query (user_id, table_name, record_id, action_type, action_time, previous_data)
    VALUES (USER_ID(), 'Quyen', @deleted_quyen_id, 'Xoá', GETDATE(), 'Dữ liệu trước khi xoá');
END;

go
-- Trigger xoá từ bảng Nhom
CREATE TRIGGER trg_DeleteNhom
ON Nhom
AFTER DELETE
AS
BEGIN
    DECLARE @deleted_nhom_id INT;
    SELECT @deleted_nhom_id = nhom_id FROM deleted;

    INSERT INTO Query (user_id, table_name, record_id, action_type, action_time, previous_data)
    VALUES (USER_ID(), 'Nhom', @deleted_nhom_id, 'Xoá', GETDATE(), 'Dữ liệu trước khi xoá');
END;

go
-- Trigger xoá từ bảng Agent
CREATE TRIGGER trg_Deletedevice
ON Device
AFTER DELETE
AS
BEGIN
    DECLARE @deleted_device_id INT;
    SELECT @deleted_device_id = device_id FROM deleted;

    INSERT INTO Query (user_id, table_name, record_id, action_type, action_time, previous_data)
    VALUES (USER_ID(), 'Agent', @deleted_device_id, 'Xoá', GETDATE(), 'Dữ liệu trước khi xoá');
END;
GO
