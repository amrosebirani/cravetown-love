import { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form, Input, InputNumber, Space, message, Popconfirm, Progress, Tooltip } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import type { TimeSlotsData, TimeSlot } from '../types';
import { loadTimeSlots, saveTimeSlots } from '../api';

const { TextArea } = Input;

// Helper to convert RGB [0-1] to hex color string
const rgbToHex = (color: [number, number, number]): string => {
  const r = Math.round(color[0] * 255);
  const g = Math.round(color[1] * 255);
  const b = Math.round(color[2] * 255);
  return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
};

// Helper to convert hex to RGB [0-1]
const hexToRgb = (hex: string): [number, number, number] => {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (result) {
    return [
      parseInt(result[1], 16) / 255,
      parseInt(result[2], 16) / 255,
      parseInt(result[3], 16) / 255
    ];
  }
  return [0.5, 0.5, 0.5];
};

const TimeSlotManager: React.FC = () => {
  const [data, setData] = useState<TimeSlotsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [editingSlot, setEditingSlot] = useState<TimeSlot | null>(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const result = await loadTimeSlots();
      setData(result);
    } catch (error) {
      message.error('Failed to load time slots');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const saveData = async (newData: TimeSlotsData) => {
    try {
      await saveTimeSlots(newData);
      setData(newData);
      message.success('Time slots saved successfully');
    } catch (error) {
      message.error('Failed to save time slots');
      console.error(error);
    }
  };

  const handleAdd = () => {
    setEditingSlot(null);
    form.resetFields();
    form.setFieldsValue({
      startHour: 0,
      endHour: 4,
      color: '#808080'
    });
    setIsModalVisible(true);
  };

  const handleEdit = (record: TimeSlot) => {
    setEditingSlot(record);
    form.setFieldsValue({
      ...record,
      color: rgbToHex(record.color)
    });
    setIsModalVisible(true);
  };

  const handleDelete = (record: TimeSlot) => {
    if (!data) return;

    const newData: TimeSlotsData = {
      ...data,
      slots: data.slots.filter(s => s.id !== record.id)
    };

    saveData(newData);
  };

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data) return;

      const slot: TimeSlot = {
        id: values.id,
        name: values.name,
        startHour: values.startHour,
        endHour: values.endHour,
        description: values.description || '',
        color: hexToRgb(values.color)
      };

      let newSlots: TimeSlot[];

      if (editingSlot) {
        // Edit existing
        newSlots = data.slots.map(s =>
          s.id === editingSlot.id ? slot : s
        );
      } else {
        // Add new - check for duplicate ID
        if (data.slots.find(s => s.id === values.id)) {
          message.error('A time slot with this ID already exists');
          return;
        }
        newSlots = [...data.slots, slot];
      }

      // Sort by startHour
      newSlots.sort((a, b) => {
        // Handle late_night (0-5) by treating hours < 5 as 24+
        const aStart = a.startHour < 5 ? a.startHour + 24 : a.startHour;
        const bStart = b.startHour < 5 ? b.startHour + 24 : b.startHour;
        return aStart - bStart;
      });

      const newData: TimeSlotsData = {
        ...data,
        slots: newSlots
      };

      await saveData(newData);
      setIsModalVisible(false);
      form.resetFields();
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  // Calculate coverage for timeline visualization
  const getSlotWidth = (slot: TimeSlot) => {
    let duration = slot.endHour - slot.startHour;
    if (duration <= 0) duration += 24; // Handle wrap around midnight
    return (duration / 24) * 100;
  };

  const getSlotStart = (slot: TimeSlot) => {
    return (slot.startHour / 24) * 100;
  };

  const columns = [
    {
      title: 'Color',
      dataIndex: 'color',
      key: 'color',
      width: 60,
      render: (color: [number, number, number]) => (
        <div
          style={{
            width: 24,
            height: 24,
            backgroundColor: rgbToHex(color),
            borderRadius: 4,
            border: '1px solid #d9d9d9'
          }}
        />
      )
    },
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 120
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      width: 140
    },
    {
      title: 'Time Range',
      key: 'timeRange',
      width: 120,
      render: (_: any, record: TimeSlot) => (
        <span>{`${record.startHour.toString().padStart(2, '0')}:00 - ${record.endHour.toString().padStart(2, '0')}:00`}</span>
      )
    },
    {
      title: 'Duration',
      key: 'duration',
      width: 80,
      render: (_: any, record: TimeSlot) => {
        let duration = record.endHour - record.startHour;
        if (duration <= 0) duration += 24;
        return `${duration}h`;
      }
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 120,
      render: (_: any, record: TimeSlot) => (
        <Space>
          <Button
            icon={<EditOutlined />}
            size="small"
            onClick={() => handleEdit(record)}
          />
          <Popconfirm
            title="Delete this time slot?"
            onConfirm={() => handleDelete(record)}
            okText="Yes"
            cancelText="No"
          >
            <Button icon={<DeleteOutlined />} size="small" danger />
          </Popconfirm>
        </Space>
      )
    }
  ];

  return (
    <div>
      <Card
        title="Time Slots"
        extra={
          <Button type="primary" icon={<PlusOutlined />} onClick={handleAdd}>
            Add Time Slot
          </Button>
        }
      >
        <p style={{ marginBottom: 16, color: '#666' }}>
          Configure the time slots that divide each game day. Cravings are mapped to specific slots.
        </p>

        {/* Timeline Visualization */}
        {data && data.slots.length > 0 && (
          <div style={{ marginBottom: 24 }}>
            <h4 style={{ marginBottom: 8 }}>24-Hour Timeline</h4>
            <div style={{
              position: 'relative',
              height: 40,
              backgroundColor: '#f0f0f0',
              borderRadius: 4,
              overflow: 'hidden'
            }}>
              {data.slots.map(slot => (
                <Tooltip
                  key={slot.id}
                  title={`${slot.name}: ${slot.startHour}:00 - ${slot.endHour}:00`}
                >
                  <div
                    style={{
                      position: 'absolute',
                      left: `${getSlotStart(slot)}%`,
                      width: `${getSlotWidth(slot)}%`,
                      height: '100%',
                      backgroundColor: rgbToHex(slot.color),
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: 11,
                      color: '#000',
                      fontWeight: 500,
                      borderRight: '1px solid rgba(0,0,0,0.1)',
                      cursor: 'pointer'
                    }}
                    onClick={() => handleEdit(slot)}
                  >
                    {slot.name}
                  </div>
                </Tooltip>
              ))}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: '#888', marginTop: 4 }}>
              <span>00:00</span>
              <span>06:00</span>
              <span>12:00</span>
              <span>18:00</span>
              <span>24:00</span>
            </div>
          </div>
        )}

        <Table
          columns={columns}
          dataSource={data?.slots || []}
          rowKey="id"
          loading={loading}
          pagination={false}
          size="small"
        />
      </Card>

      <Modal
        title={editingSlot ? 'Edit Time Slot' : 'Add Time Slot'}
        open={isModalVisible}
        onOk={handleModalOk}
        onCancel={() => {
          setIsModalVisible(false);
          form.resetFields();
        }}
        width={500}
      >
        <Form form={form} layout="vertical">
          <Form.Item
            name="id"
            label="ID"
            rules={[
              { required: true, message: 'Please enter an ID' },
              { pattern: /^[a-z_]+$/, message: 'ID should be lowercase with underscores only' }
            ]}
          >
            <Input placeholder="e.g., early_morning" disabled={!!editingSlot} />
          </Form.Item>

          <Form.Item
            name="name"
            label="Display Name"
            rules={[{ required: true, message: 'Please enter a name' }]}
          >
            <Input placeholder="e.g., Early Morning" />
          </Form.Item>

          <Space style={{ width: '100%' }} size="large">
            <Form.Item
              name="startHour"
              label="Start Hour"
              rules={[{ required: true, message: 'Required' }]}
            >
              <InputNumber min={0} max={23} style={{ width: 100 }} />
            </Form.Item>

            <Form.Item
              name="endHour"
              label="End Hour"
              rules={[{ required: true, message: 'Required' }]}
            >
              <InputNumber min={0} max={24} style={{ width: 100 }} />
            </Form.Item>
          </Space>

          <Form.Item
            name="color"
            label="Color"
            rules={[{ required: true, message: 'Please select a color' }]}
          >
            <Input type="color" style={{ width: 60, height: 32 }} />
          </Form.Item>

          <Form.Item
            name="description"
            label="Description"
          >
            <TextArea rows={2} placeholder="What activities happen during this slot?" />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default TimeSlotManager;
