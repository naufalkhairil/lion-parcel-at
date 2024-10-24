-- Create enum status
CREATE TYPE transaction_status AS ENUM ('INITIATED', 'PROCESSING', 'DONE', 'CANCELLED');

-- Create the retail_transactions table
CREATE TABLE IF NOT EXISTS retail_transactions (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(255) NOT NULL,
    last_status transaction_status NOT NULL,
    pos_origin VARCHAR(255),
    pos_destination VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Trigger function for setting updated_at when the row is updated
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for setting deleted_at when last_status is 'DONE'
CREATE OR REPLACE FUNCTION set_deleted_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.last_status = 'DONE' THEN
        NEW.deleted_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at column on row update
CREATE TRIGGER trigger_update_timestamp
BEFORE UPDATE ON retail_transactions
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Trigger to update deleted_at when last_status becomes 'DONE'
CREATE TRIGGER trigger_set_deleted_at
BEFORE UPDATE ON retail_transactions
FOR EACH ROW
EXECUTE FUNCTION set_deleted_at();

-- Insert dummy records
INSERT INTO retail_transactions (customer_id, last_status, pos_origin, pos_destination)
VALUES 
('CUST001', 'INITIATED', 'Store1', 'Store2'),
('CUST002', 'PROCESSING', 'Store2', 'Store3'),
('CUST004', 'CANCELLED', 'Store3', 'Store2');
