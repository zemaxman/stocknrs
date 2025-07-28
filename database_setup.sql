-- ===================================
-- ระบบจัดการสต็อกสินค้า - Database Setup
-- ===================================

-- 1. สร้างตาราง categories (หมวดหมู่สินค้า)
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. สร้างตาราง suppliers (ผู้จัดหา)
CREATE TABLE IF NOT EXISTS suppliers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(50),
  address TEXT,
  contact_person VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. สร้างตาราง products (สินค้า)
CREATE TABLE IF NOT EXISTS products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  sku VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL,
  unit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  current_stock INTEGER NOT NULL DEFAULT 0,
  min_stock INTEGER NOT NULL DEFAULT 0,
  max_stock INTEGER,
  unit VARCHAR(50) DEFAULT 'ชิ้น',
  location VARCHAR(255),
  barcode VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. สร้างตาราง movements (การเคลื่อนไหวสต็อก)
CREATE TABLE IF NOT EXISTS movements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  type VARCHAR(10) NOT NULL CHECK (type IN ('in', 'out')),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  reason VARCHAR(255),
  reference VARCHAR(255),
  notes TEXT,
  created_by VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. สร้าง indexes สำหรับการค้นหาที่เร็วขึ้น
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_supplier_id ON products(supplier_id);
CREATE INDEX IF NOT EXISTS idx_movements_product_id ON movements(product_id);
CREATE INDEX IF NOT EXISTS idx_movements_type ON movements(type);
CREATE INDEX IF NOT EXISTS idx_movements_created_at ON movements(created_at);

-- 6. สร้าง trigger function สำหรับอัพเดท updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- 7. สร้าง triggers สำหรับ updated_at
CREATE TRIGGER update_categories_updated_at 
  BEFORE UPDATE ON categories 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at 
  BEFORE UPDATE ON suppliers 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at 
  BEFORE UPDATE ON products 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. สร้าง RLS (Row Level Security) policies
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE movements ENABLE ROW LEVEL SECURITY;

-- สร้าง policies สำหรับการอ่านและเขียนข้อมูล (อนุญาตทุกคน)
CREATE POLICY "Allow all operations on categories" ON categories FOR ALL USING (true);
CREATE POLICY "Allow all operations on suppliers" ON suppliers FOR ALL USING (true);
CREATE POLICY "Allow all operations on products" ON products FOR ALL USING (true);
CREATE POLICY "Allow all operations on movements" ON movements FOR ALL USING (true);

-- 9. เพิ่มข้อมูลตัวอย่างสำหรับ categories
INSERT INTO categories (name, description) VALUES
('อุปกรณ์สำนักงาน', 'เครื่องเขียนและอุปกรณ์สำหรับการทำงานในสำนักงาน'),
('อุปกรณ์คอมพิวเตอร์', 'อุปกรณ์และอะไหล่คอมพิวเตอร์'),
('วัสดุทำความสะอาด', 'ผลิตภัณฑ์และอุปกรณ์ทำความสะอาด'),
('วัสดุก่อสร้าง', 'วัสดุและอุปกรณ์สำหรับการก่อสร้าง'),
('เครื่องใช้ไฟฟ้า', 'อุปกรณ์และเครื่องใช้ไฟฟ้าต่างๆ')
ON CONFLICT (name) DO NOTHING;

-- 10. เพิ่มข้อมูลตัวอย่างสำหรับ suppliers
INSERT INTO suppliers (name, email, phone, address, contact_person) VALUES
('บริษัท โอเอ็กซ์ จำกัด', 'contact@ox.co.th', '02-123-4567', '123 ถนนสุขุมวิท กรุงเทพฯ 10110', 'คุณสมชาย'),
('ห้างหุ้นส่วน เทคโนโลยี', 'info@techno.com', '02-234-5678', '456 ถนนพหลโยธิน กรุงเทพฯ 10400', 'คุณสมหญิง'),
('บริษัท คลีน โซลูชั่น จำกัด', 'sales@cleansolution.co.th', '02-345-6789', '789 ถนนลาดพร้าว กรุงเทพฯ 10230', 'คุณสมปอง'),
('ร้านวัสดุก่อสร้าง สมบูรณ์', 'somboon@construction.com', '02-456-7890', '321 ถนนรามคำแหง กรุงเทพฯ 10240', 'คุณสมบูรณ์'),
('บริษัท อีเลคทริค พลัส จำกัด', 'contact@electricplus.co.th', '02-567-8901', '654 ถนนพระราม 4 กรุงเทพฯ 10500', 'คุณสมเกียรติ')
ON CONFLICT (email) DO NOTHING;

-- 11. เพิ่มข้อมูลตัวอย่างสำหรับ products
INSERT INTO products (name, sku, description, category_id, supplier_id, unit_price, current_stock, min_stock, max_stock, unit) VALUES
('ปากกาลูกลื่น สีน้ำเงิน', 'PEN-001', 'ปากกาลูกลื่น หมึกสีน้ำเงิน', 
  (SELECT id FROM categories WHERE name = 'อุปกรณ์สำนักงาน' LIMIT 1),
  (SELECT id FROM suppliers WHERE name = 'บริษัท โอเอ็กซ์ จำกัด' LIMIT 1),
  15.00, 150, 20, 500, 'ด้าม'),
  
('กระดาษ A4 80 แกรม', 'PAPER-001', 'กระดาษ A4 80 แกรม สีขาว', 
  (SELECT id FROM categories WHERE name = 'อุปกรณ์สำนักงาน' LIMIT 1),
  (SELECT id FROM suppliers WHERE name = 'บริษัท โอเอ็กซ์ จำกัด' LIMIT 1),
  120.00, 50, 10, 200, 'รีม'),
  
('หนู Wireless', 'MOUSE-001', 'หนูไร้สาย 2.4GHz สีดำ', 
  (SELECT id FROM categories WHERE name = 'อุปกรณ์คอมพิวเตอร์' LIMIT 1),
  (SELECT id FROM suppliers WHERE name = 'ห้างหุ้นส่วน เทคโนโลยี' LIMIT 1),
  350.00, 25, 5, 100, 'ตัว'),
  
('น้ำยาทำความสะอาดพื้น', 'CLEAN-001', 'น้ำยาทำความสะอาดพื้น ขนาด 1 ลิตร', 
  (SELECT id FROM categories WHERE name = 'วัสดุทำความสะอาด' LIMIT 1),
  (SELECT id FROM suppliers WHERE name = 'บริษัท คลีน โซลูชั่น จำกัด' LIMIT 1),
  85.00, 30, 10, 150, 'ขวด'),
  
('สีทาบ้าน สีขาว', 'PAINT-001', 'สีทาบ้าน สีขาว ขนาด 1 แกลลอน', 
  (SELECT id FROM categories WHERE name = 'วัสดุก่อสร้าง' LIMIT 1),
  (SELECT id FROM suppliers WHERE name = 'ร้านวัสดุก่อสร้าง สมบูรณ์' LIMIT 1),
  450.00, 15, 5, 50, 'กระป๋อง')
ON CONFLICT (sku) DO NOTHING;

-- 12. เพิ่มข้อมูลตัวอย่างสำหรับ movements
INSERT INTO movements (product_id, type, quantity, reason, reference, created_by) VALUES
((SELECT id FROM products WHERE sku = 'PEN-001' LIMIT 1), 'in', 100, 'รับสินค้าเข้า', 'PO-2024-001', 'admin'),
((SELECT id FROM products WHERE sku = 'PAPER-001' LIMIT 1), 'in', 50, 'รับสินค้าเข้า', 'PO-2024-002', 'admin'),
((SELECT id FROM products WHERE sku = 'PEN-001' LIMIT 1), 'out', 20, 'เบิกใช้ภายใน', 'REQ-2024-001', 'user1'),
((SELECT id FROM products WHERE sku = 'MOUSE-001' LIMIT 1), 'in', 30, 'รับสินค้าเข้า', 'PO-2024-003', 'admin'),
((SELECT id FROM products WHERE sku = 'CLEAN-001' LIMIT 1), 'out', 5, 'ใช้ทำความสะอาด', 'REQ-2024-002', 'user2');

-- 13. สร้าง function สำหรับอัพเดทสต็อกอัตโนมัติ
CREATE OR REPLACE FUNCTION update_product_stock()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.type = 'in' THEN
    UPDATE products 
    SET current_stock = current_stock + NEW.quantity
    WHERE id = NEW.product_id;
  ELSIF NEW.type = 'out' THEN
    UPDATE products 
    SET current_stock = GREATEST(0, current_stock - NEW.quantity)
    WHERE id = NEW.product_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 14. สร้าง trigger สำหรับอัพเดทสต็อกอัตโนมัติ
CREATE TRIGGER trigger_update_product_stock
  AFTER INSERT ON movements
  FOR EACH ROW
  EXECUTE FUNCTION update_product_stock();

-- 15. สร้าง view สำหรับรายงาน
CREATE OR REPLACE VIEW stock_summary AS
SELECT 
  p.id,
  p.name,
  p.sku,
  p.current_stock,
  p.min_stock,
  p.max_stock,
  p.unit_price,
  (p.current_stock * p.unit_price) as stock_value,
  c.name as category_name,
  s.name as supplier_name,
  CASE 
    WHEN p.current_stock <= 0 THEN 'หมดสต็อก'
    WHEN p.current_stock <= p.min_stock THEN 'สต็อกต่ำ'
    ELSE 'ปกติ'
  END as stock_status
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN suppliers s ON p.supplier_id = s.id;

-- สิ้นสุดการตั้งค่าฐานข้อมูล
-- คุณสามารถรันคำสั่ง SQL นี้ใน Supabase SQL Editor