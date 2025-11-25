import { useState } from 'react';
import { Modal, Select, Table, Button, message, Tag, Space, Card } from 'antd';
import { ThunderboltOutlined } from '@ant-design/icons';
import type { Commodity } from '../types';
import { FULFILLMENT_TEMPLATES, QUALITY_MULTIPLIERS, type VectorTemplate } from '../constants';

interface QuickFillModalProps {
  visible: boolean;
  onClose: () => void;
  commodities: Commodity[];
  existingFulfillmentIds: string[];
  onApply: (fills: Array<{ commodityId: string; template: VectorTemplate; qualityPreset: string }>) => void;
}

const QuickFillModal: React.FC<QuickFillModalProps> = ({
  visible,
  onClose,
  commodities,
  existingFulfillmentIds,
  onApply,
}) => {
  const [selectedCommodities, setSelectedCommodities] = useState<string[]>([]);
  const [templateMapping, setTemplateMapping] = useState<Record<string, string>>({});
  const [qualityMapping, setQualityMapping] = useState<Record<string, string>>({});

  // Get commodities that don't have fulfillment vectors yet
  const missingFulfillments = commodities.filter(c => !existingFulfillmentIds.includes(c.id));

  // Auto-suggest template based on category
  const suggestTemplate = (category: string): string => {
    const categoryLower = category.toLowerCase();

    if (categoryLower === 'grain') return 'grain';
    if (categoryLower === 'fruit') return 'fruit';
    if (categoryLower === 'vegetable') return 'vegetable';
    if (categoryLower === 'animal_product') return 'animal_product';
    if (categoryLower === 'processed_food') return 'processed_food';
    if (categoryLower.includes('cloth')) return 'clothing_basic';
    if (categoryLower === 'furniture') return 'furniture';
    if (categoryLower === 'tools') return 'tools';
    if (categoryLower === 'luxury') return 'luxury';
    if (categoryLower.includes('textile')) {
      return categoryLower.includes('raw') ? 'textile_raw' : 'textile';
    }
    if (categoryLower === 'construction') return 'construction';
    if (categoryLower.includes('mineral')) return 'raw_mineral';
    if (categoryLower.includes('metal')) return 'refined_metal';
    if (categoryLower === 'fuel') return 'fuel';
    if (categoryLower === 'dye') return 'dye';
    if (categoryLower === 'seed') return 'seed';
    if (categoryLower === 'plant') return 'plant';
    if (categoryLower === 'misc') return 'crafting';

    return 'grain'; // default
  };

  // Auto-suggest quality preset
  const suggestQuality = (category: string, baseValue: number): string => {
    const categoryLower = category.toLowerCase();

    if (categoryLower === 'luxury') return 'luxury_goods';
    if (categoryLower.includes('cloth')) return 'clothing';
    if (categoryLower === 'furniture') return 'furniture';
    if (categoryLower === 'tools') return 'tools';
    if (categoryLower.includes('mineral') || categoryLower.includes('metal') || categoryLower === 'seed') {
      return 'raw_materials';
    }

    // Food categories - check value
    if (baseValue >= 15) return 'luxury_food';
    return 'basic_food';
  };

  const handleSelectAll = () => {
    const allIds = missingFulfillments.map(c => c.id);
    setSelectedCommodities(allIds);

    // Auto-fill templates and quality for all
    const newTemplateMapping: Record<string, string> = {};
    const newQualityMapping: Record<string, string> = {};

    missingFulfillments.forEach(c => {
      newTemplateMapping[c.id] = suggestTemplate(c.category);
      newQualityMapping[c.id] = suggestQuality(c.category, c.baseValue);
    });

    setTemplateMapping(newTemplateMapping);
    setQualityMapping(newQualityMapping);
  };

  const handleApply = () => {
    if (selectedCommodities.length === 0) {
      message.warning('Please select at least one commodity');
      return;
    }

    const fills = selectedCommodities.map(id => ({
      commodityId: id,
      template: FULFILLMENT_TEMPLATES[templateMapping[id] || 'grain'],
      qualityPreset: qualityMapping[id] || 'basic_food',
    }));

    onApply(fills);
    message.success(`Applied templates to ${fills.length} commodities`);
    onClose();

    // Reset
    setSelectedCommodities([]);
    setTemplateMapping({});
    setQualityMapping({});
  };

  const columns = [
    {
      title: 'Select',
      key: 'select',
      width: 60,
      render: (_: any, record: Commodity) => (
        <input
          type="checkbox"
          checked={selectedCommodities.includes(record.id)}
          onChange={(e) => {
            if (e.target.checked) {
              setSelectedCommodities([...selectedCommodities, record.id]);
              // Auto-suggest template when selected
              setTemplateMapping({
                ...templateMapping,
                [record.id]: suggestTemplate(record.category),
              });
              setQualityMapping({
                ...qualityMapping,
                [record.id]: suggestQuality(record.category, record.baseValue),
              });
            } else {
              setSelectedCommodities(selectedCommodities.filter(id => id !== record.id));
            }
          }}
        />
      ),
    },
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 150,
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      width: 150,
    },
    {
      title: 'Category',
      dataIndex: 'category',
      key: 'category',
      width: 150,
      render: (category: string) => <Tag>{category}</Tag>,
    },
    {
      title: 'Template',
      key: 'template',
      width: 200,
      render: (_: any, record: Commodity) => (
        <Select
          value={templateMapping[record.id] || suggestTemplate(record.category)}
          onChange={(value) => {
            setTemplateMapping({ ...templateMapping, [record.id]: value });
            // Auto-select commodity when template is changed
            if (!selectedCommodities.includes(record.id)) {
              setSelectedCommodities([...selectedCommodities, record.id]);
            }
          }}
          style={{ width: '100%' }}
          size="small"
        >
          {Object.keys(FULFILLMENT_TEMPLATES).map(key => (
            <Select.Option key={key} value={key}>
              {key.replace(/_/g, ' ')}
            </Select.Option>
          ))}
        </Select>
      ),
    },
    {
      title: 'Quality Preset',
      key: 'quality',
      width: 180,
      render: (_: any, record: Commodity) => (
        <Select
          value={qualityMapping[record.id] || suggestQuality(record.category, record.baseValue)}
          onChange={(value) => {
            setQualityMapping({ ...qualityMapping, [record.id]: value });
            // Auto-select commodity when quality is changed
            if (!selectedCommodities.includes(record.id)) {
              setSelectedCommodities([...selectedCommodities, record.id]);
            }
          }}
          style={{ width: '100%' }}
          size="small"
        >
          {Object.keys(QUALITY_MULTIPLIERS).map(key => (
            <Select.Option key={key} value={key}>
              {key.replace(/_/g, ' ')}
            </Select.Option>
          ))}
        </Select>
      ),
    },
  ];

  return (
    <Modal
      title={
        <Space>
          <ThunderboltOutlined />
          <span>Quick Fill Fulfillment Vectors</span>
        </Space>
      }
      open={visible}
      onCancel={onClose}
      width={1200}
      footer={[
        <Button key="cancel" onClick={onClose}>
          Cancel
        </Button>,
        <Button key="select-all" onClick={handleSelectAll}>
          Select All & Auto-Fill
        </Button>,
        <Button
          key="apply"
          type="primary"
          onClick={handleApply}
          disabled={selectedCommodities.length === 0}
        >
          Apply Templates ({selectedCommodities.length} selected)
        </Button>,
      ]}
    >
      <Space direction="vertical" style={{ width: '100%' }} size="large">
        <Card size="small" style={{ background: '#f0f2f5' }}>
          <p>
            <strong>{missingFulfillments.length} commodities</strong> are missing fulfillment vectors.
          </p>
          <p>
            Select commodities and choose templates to quickly generate fulfillment vectors based on their category.
            Templates will be auto-suggested based on commodity category.
          </p>
        </Card>

        <Table
          columns={columns}
          dataSource={missingFulfillments}
          rowKey="id"
          pagination={{ pageSize: 10 }}
          size="small"
          scroll={{ y: 400 }}
        />
      </Space>
    </Modal>
  );
};

export default QuickFillModal;
