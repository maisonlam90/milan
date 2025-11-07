import React, { useState, useEffect } from 'react';
import {
  Form,
  Input,
  Button,
  Table,
  InputNumber,
  Select,
  DatePicker,
  message,
  Space,
  Divider,
  Card,
  Row,
  Col,
  Tabs,
} from 'antd';
import { PlusOutlined, DeleteOutlined, SaveOutlined } from '@ant-design/icons';
import dayjs from 'dayjs';
import api from '../../../../service/api';

interface InvoiceLine {
  product_id?: string;
  name?: string;
  quantity?: number;
  price_unit?: number;
  discount?: number;
  account_id?: string;
}

interface CreateInvoicePayload {
  name: string;
  ref?: string;
  date: string;
  journal_id: string;
  currency_id?: string;
  move_type: string;
  partner_id?: string;
  commercial_partner_id?: string;
  invoice_date?: string;
  invoice_date_due?: string;
  invoice_origin?: string;
  payment_term_id?: string;
  invoice_user_id?: string;
  fiscal_position_id?: string;
  narration?: string;
  lines: InvoiceLine[];
}

const InvoiceCreate: React.FC = () => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [lines, setLines] = useState<InvoiceLine[]>([
    { product_id: '', name: '', quantity: 1, price_unit: 0, discount: 0 },
  ]);
  const [contacts, setContacts] = useState<any[]>([]);
  const [journals, setJournals] = useState<any[]>([]);
  const [currencies, setCurrencies] = useState<any[]>([]);
  const [products, setProducts] = useState<any[]>([]);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      // Fetch contacts
      const contactsRes = await api.get('/contact/list?limit=100');
      setContacts(contactsRes.data?.data || []);

      // Fetch journals
      const journalsRes = await api.get('/journal/list?limit=100');
      setJournals(journalsRes.data?.data || []);

      // Fetch currencies (if available)
      try {
        const currenciesRes = await api.get('/currency/list?limit=100');
        setCurrencies(currenciesRes.data?.data || []);
      } catch {
        // Currency endpoint may not exist
      }

      // Fetch products (if available)
      try {
        const productsRes = await api.get('/product/list?limit=100');
        setProducts(productsRes.data?.data || []);
      } catch {
        // Product endpoint may not exist
      }
    } catch (error: any) {
      message.error('Failed to load data');
    }
  };

  const handleAddLine = () => {
    setLines([...lines, { product_id: '', name: '', quantity: 1, price_unit: 0, discount: 0 }]);
  };

  const handleRemoveLine = (index: number) => {
    if (lines.length > 1) {
      setLines(lines.filter((_, i) => i !== index));
    } else {
      message.warning('Must have at least one line');
    }
  };

  const handleLineChange = (index: number, field: string, value: any) => {
    const newLines = [...lines];
    newLines[index] = { ...newLines[index], [field]: value };
    setLines(newLines);
  };

  const calculateLineTotal = (line: InvoiceLine) => {
    const qty = line.quantity || 0;
    const price = line.price_unit || 0;
    const discount = line.discount || 0;
    return qty * price * (1 - discount / 100);
  };

  const calculateTotals = () => {
    let subtotal = 0;
    lines.forEach((line) => {
      subtotal += calculateLineTotal(line);
    });
    const tax = subtotal * 0.1; // Assume 10% tax
    return {
      subtotal,
      tax,
      total: subtotal + tax,
    };
  };

  const totals = calculateTotals();

  const handleSubmit = async (values: any) => {
    // Validate lines
    const validLines = lines.filter((l) => l.name || l.product_id);
    if (validLines.length === 0) {
      message.error('Please add at least one invoice line');
      return;
    }

    try {
      setLoading(true);
      const payload: CreateInvoicePayload = {
        name: values.name,
        ref: values.ref,
        date: values.date.format('YYYY-MM-DD'),
        journal_id: values.journal_id,
        currency_id: values.currency_id,
        move_type: values.move_type,
        partner_id: values.partner_id,
        invoice_date: values.invoice_date?.format('YYYY-MM-DD'),
        invoice_date_due: values.invoice_date_due?.format('YYYY-MM-DD'),
        invoice_origin: values.invoice_origin,
        narration: values.narration,
        lines: validLines,
      };

      const response = await api.post('/invoice/create', payload);
      message.success('Invoice created successfully');
      
      // Navigate to invoice detail
      if (response.data?.data?.id) {
        window.location.href = `/invoice/${response.data.data.id}`;
      } else {
        form.resetFields();
        setLines([{ product_id: '', name: '', quantity: 1, price_unit: 0, discount: 0 }]);
      }
    } catch (error: any) {
      message.error(error.response?.data?.message || 'Failed to create invoice');
    } finally {
      setLoading(false);
    }
  };

  const lineColumns = [
    {
      title: 'Product',
      dataIndex: 'product_id',
      key: 'product_id',
      width: '15%',
      render: (value: any, _: any, index: number) => (
        <Select
          placeholder="Select product"
          value={value}
          allowClear
          showSearch
          onChange={(v) => handleLineChange(index, 'product_id', v)}
        >
          {products.map((p: any) => (
            <Select.Option key={p.id} value={p.id}>
              {p.name}
            </Select.Option>
          ))}
        </Select>
      ),
    },
    {
      title: 'Description',
      dataIndex: 'name',
      key: 'name',
      render: (value: any, _: any, index: number) => (
        <Input
          placeholder="Description"
          value={value}
          onChange={(e) => handleLineChange(index, 'name', e.target.value)}
        />
      ),
    },
    {
      title: 'Qty',
      dataIndex: 'quantity',
      key: 'quantity',
      width: 80,
      render: (value: any, _: any, index: number) => (
        <InputNumber
          value={value}
          min={0}
          precision={2}
          onChange={(v) => handleLineChange(index, 'quantity', v)}
        />
      ),
    },
    {
      title: 'Unit Price',
      dataIndex: 'price_unit',
      key: 'price_unit',
      width: 100,
      render: (value: any, _: any, index: number) => (
        <InputNumber
          value={value}
          min={0}
          precision={2}
          onChange={(v) => handleLineChange(index, 'price_unit', v)}
        />
      ),
    },
    {
      title: 'Discount %',
      dataIndex: 'discount',
      key: 'discount',
      width: 80,
      render: (value: any, _: any, index: number) => (
        <InputNumber
          value={value}
          min={0}
          max={100}
          precision={2}
          onChange={(v) => handleLineChange(index, 'discount', v)}
        />
      ),
    },
    {
      title: 'Subtotal',
      key: 'subtotal',
      width: 120,
      render: (_: any, record: InvoiceLine) => {
        const total = calculateLineTotal(record);
        return <span>₫{total.toLocaleString('vi-VN')}</span>;
      },
    },
    {
      title: 'Action',
      key: 'action',
      width: 60,
      render: (_: any, _record: InvoiceLine, index: number) => (
        <Button
          danger
          size="small"
          icon={<DeleteOutlined />}
          onClick={() => handleRemoveLine(index)}
        />
      ),
    },
  ];

  return (
    <div style={{ padding: '24px', maxWidth: '1400px', margin: '0 auto' }}>
      <h1>Create Invoice</h1>

      <Form form={form} layout="vertical" onFinish={handleSubmit}>
        <Card style={{ marginBottom: '24px' }}>
          <Row gutter={16}>
            <Col xs={24} md={12}>
              <Form.Item
                label="Invoice Number"
                name="name"
                rules={[{ required: true, message: 'Invoice number is required' }]}
              >
                <Input placeholder="INV-001" />
              </Form.Item>
            </Col>
            <Col xs={24} md={12}>
              <Form.Item label="Reference" name="ref">
                <Input placeholder="Reference" />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col xs={24} md={6}>
              <Form.Item
                label="Date"
                name="date"
                rules={[{ required: true, message: 'Date is required' }]}
                initialValue={dayjs()}
              >
                <DatePicker style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col xs={24} md={6}>
              <Form.Item
                label="Journal"
                name="journal_id"
                rules={[{ required: true, message: 'Journal is required' }]}
              >
                <Select placeholder="Select journal" showSearch>
                  {journals.map((j: any) => (
                    <Select.Option key={j.id} value={j.id}>
                      {j.name}
                    </Select.Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
            <Col xs={24} md={6}>
              <Form.Item
                label="Type"
                name="move_type"
                rules={[{ required: true, message: 'Type is required' }]}
                initialValue="out_invoice"
              >
                <Select placeholder="Select type">
                  <Select.Option value="out_invoice">Customer Invoice</Select.Option>
                  <Select.Option value="in_invoice">Vendor Bill</Select.Option>
                  <Select.Option value="out_refund">Credit Note</Select.Option>
                  <Select.Option value="in_refund">Vendor Credit</Select.Option>
                </Select>
              </Form.Item>
            </Col>
            <Col xs={24} md={6}>
              <Form.Item label="Currency" name="currency_id">
                <Select placeholder="Select currency" allowClear showSearch>
                  {currencies.map((c: any) => (
                    <Select.Option key={c.id} value={c.id}>
                      {c.name}
                    </Select.Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col xs={24} md={12}>
              <Form.Item label="Partner" name="partner_id">
                <Select placeholder="Select partner" allowClear showSearch>
                  {contacts.map((c: any) => (
                    <Select.Option key={c.id} value={c.id}>
                      {c.name || c.display_name || '(No name)'}
                    </Select.Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
            <Col xs={24} md={12}>
              <Form.Item label="Invoice Origin" name="invoice_origin">
                <Input placeholder="Origin (e.g., Sales Order)" />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col xs={24} md={12}>
              <Form.Item label="Invoice Date" name="invoice_date">
                <DatePicker style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col xs={24} md={12}>
              <Form.Item label="Due Date" name="invoice_date_due">
                <DatePicker style={{ width: '100%' }} />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item label="Narration / Notes" name="narration">
            <Input.TextArea placeholder="Additional notes" rows={2} />
          </Form.Item>
        </Card>

        <Card style={{ marginBottom: '24px' }}>
          <div style={{ marginBottom: '16px' }}>
            <h3>Invoice Lines</h3>
          </div>
          <Table
            columns={lineColumns}
            dataSource={lines}
            pagination={false}
            rowKey={(_, index) => index}
            size="small"
            scroll={{ x: 800 }}
          />
          <Button
            type="dashed"
            icon={<PlusOutlined />}
            onClick={handleAddLine}
            style={{ marginTop: '12px' }}
            block
          >
            Add Invoice Line
          </Button>
        </Card>

        <Card style={{ marginBottom: '24px', backgroundColor: '#fafafa' }}>
          <Row justify="end" gutter={16}>
            <Col xs={24} md={8}>
              <Row justify="space-between" style={{ marginBottom: '12px' }}>
                <span>Subtotal:</span>
                <strong>₫{totals.subtotal.toLocaleString('vi-VN')}</strong>
              </Row>
              <Row justify="space-between" style={{ marginBottom: '12px' }}>
                <span>Tax (10%):</span>
                <strong>₫{totals.tax.toLocaleString('vi-VN')}</strong>
              </Row>
              <Divider style={{ margin: '12px 0' }} />
              <Row justify="space-between" style={{ fontSize: '18px' }}>
                <span>
                  <strong>Total:</strong>
                </span>
                <strong style={{ color: '#1890ff' }}>₫{totals.total.toLocaleString('vi-VN')}</strong>
              </Row>
            </Col>
          </Row>
        </Card>

        <Form.Item>
          <Space size="large">
            <Button type="primary" htmlType="submit" loading={loading} icon={<SaveOutlined />} size="large">
              Create Invoice
            </Button>
            <Button size="large" onClick={() => window.history.back()}>
              Cancel
            </Button>
          </Space>
        </Form.Item>
      </Form>
    </div>
  );
};

export default InvoiceCreate;