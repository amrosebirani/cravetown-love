import { useState, useEffect } from 'react';
import { Button, Space, InputNumber, Tag, Modal, Input, List, message } from 'antd';
import { PlusOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import { loadCommodities } from '../api';
import type { Commodity } from '../types';

interface InputOutputEditorProps {
  value: Record<string, number>;
  onChange: (value: Record<string, number>) => void;
  type: 'inputs' | 'outputs';
}

const InputOutputEditor = ({ value, onChange, type }: InputOutputEditorProps) => {
  const [pickerVisible, setPickerVisible] = useState(false);
  const [commodities, setCommodities] = useState<Commodity[]>([]);
  const [searchText, setSearchText] = useState('');
  const [loading, setLoading] = useState(false);
  const [messageApi, contextHolder] = message.useMessage();

  useEffect(() => {
    if (pickerVisible && commodities.length === 0) {
      loadCommoditiesList();
    }
  }, [pickerVisible]);

  const loadCommoditiesList = async () => {
    setLoading(true);
    try {
      const data = await loadCommodities();
      setCommodities(data.commodities);
    } catch (error) {
      messageApi.error(`Failed to load commodities: ${error}`);
      console.error('Failed to load commodities:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAdd = (commodityId: string) => {
    if (!value[commodityId]) {
      onChange({ ...value, [commodityId]: 1 });
    }
    setPickerVisible(false);
    setSearchText('');
  };

  const handleQuantityChange = (commodityId: string, quantity: number | null) => {
    if (quantity && quantity > 0) {
      onChange({ ...value, [commodityId]: quantity });
    }
  };

  const handleRemove = (commodityId: string) => {
    const newValue = { ...value };
    delete newValue[commodityId];
    onChange(newValue);
  };

  const filteredCommodities = commodities.filter(c =>
    c.name.toLowerCase().includes(searchText.toLowerCase()) ||
    c.id.toLowerCase().includes(searchText.toLowerCase()) ||
    (c.category && c.category.toLowerCase().includes(searchText.toLowerCase()))
  );

  // Group commodities by category
  const commoditiesByCategory = filteredCommodities.reduce((acc, commodity) => {
    const category = commodity.category || 'Uncategorized';
    if (!acc[category]) {
      acc[category] = [];
    }
    acc[category].push(commodity);
    return acc;
  }, {} as Record<string, Commodity[]>);

  return (
    <>
      {contextHolder}
      <div style={{
        border: '1px solid #d9d9d9',
        borderRadius: '6px',
        padding: '12px',
        minHeight: '80px',
        background: '#fafafa'
      }}>
        <Space direction="vertical" style={{ width: '100%' }} size="small">
          {Object.entries(value).map(([commodityId, quantity]) => (
            <div key={commodityId} style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              padding: '8px',
              background: 'white',
              borderRadius: '4px',
              border: '1px solid #e0e0e0'
            }}>
              <Tag color="blue">{commodityId}</Tag>
              <Space>
                <InputNumber
                  min={1}
                  value={quantity}
                  onChange={(val) => handleQuantityChange(commodityId, val)}
                  style={{ width: '80px' }}
                  size="small"
                />
                <Button
                  type="text"
                  danger
                  icon={<DeleteOutlined />}
                  onClick={() => handleRemove(commodityId)}
                  size="small"
                />
              </Space>
            </div>
          ))}

          {Object.keys(value).length === 0 && (
            <div style={{ color: '#999', textAlign: 'center', padding: '16px' }}>
              No {type} added yet
            </div>
          )}

          <Button
            type="dashed"
            icon={<PlusOutlined />}
            onClick={() => setPickerVisible(true)}
            style={{ width: '100%' }}
          >
            Add {type === 'inputs' ? 'Input' : 'Output'}
          </Button>
        </Space>
      </div>

      <Modal
        title={`Select ${type === 'inputs' ? 'Input' : 'Output'} Commodity`}
        open={pickerVisible}
        onCancel={() => {
          setPickerVisible(false);
          setSearchText('');
        }}
        footer={null}
        width={600}
      >
        <Input
          placeholder="Search commodities..."
          prefix={<SearchOutlined />}
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          style={{ marginBottom: '16px' }}
        />

        <div style={{ maxHeight: '400px', overflowY: 'auto' }}>
          {Object.entries(commoditiesByCategory).map(([category, items]) => (
            <div key={category} style={{ marginBottom: '16px' }}>
              <div style={{
                fontWeight: 'bold',
                padding: '8px',
                background: '#f0f0f0',
                borderRadius: '4px',
                marginBottom: '8px'
              }}>
                {category}
              </div>
              <List
                dataSource={items}
                loading={loading}
                renderItem={(commodity) => (
                  <List.Item
                    style={{
                      cursor: 'pointer',
                      padding: '8px 16px',
                      background: value[commodity.id] ? '#e6f7ff' : 'transparent'
                    }}
                    onClick={() => handleAdd(commodity.id)}
                  >
                    <List.Item.Meta
                      title={
                        <Space>
                          {commodity.name}
                          {value[commodity.id] && <Tag color="blue">Selected</Tag>}
                        </Space>
                      }
                      description={
                        <Space>
                          <Tag>{commodity.id}</Tag>
                          {commodity.description && (
                            <span style={{ color: '#666', fontSize: '12px' }}>
                              {commodity.description}
                            </span>
                          )}
                        </Space>
                      }
                    />
                  </List.Item>
                )}
              />
            </div>
          ))}

          {filteredCommodities.length === 0 && !loading && (
            <div style={{ textAlign: 'center', padding: '32px', color: '#999' }}>
              No commodities found
            </div>
          )}
        </div>
      </Modal>
    </>
  );
};

export default InputOutputEditor;
