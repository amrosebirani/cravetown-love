import { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form, Input, Select, InputNumber, Space, message, Popconfirm, Tabs, Row, Col, Divider, Tag, Switch, Alert, Tooltip } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, MinusCircleOutlined, InfoCircleOutlined, HomeOutlined, DollarOutlined, UserOutlined } from '@ant-design/icons';
import type { StartingLocationsData, StartingLocation, LocationTerrain, StarterBuilding, StarterResource, MountainPosition, StarterCitizen, WorkerType, StarterCitizenV2, StarterBuildingV2, StarterLandPlot, IntendedRole, EconomicSystemType } from '../types';
import { loadStartingLocations, saveStartingLocations, loadBuildingTypes, loadCommodities, loadCharacterClasses, loadWorkerTypes, loadCharacterTraits } from '../api';
import type { BuildingType, Commodity, CharacterClass, CharacterTrait } from '../types';

const { TextArea } = Input;
const { TabPane } = Tabs;

const RIVER_POSITIONS = ['none', 'center', 'east', 'west'] as const;

// Role definitions with default starting wealth
const INTENDED_ROLES: { value: IntendedRole; label: string; defaultWealth: number; description: string }[] = [
  { value: 'wealthy', label: 'Wealthy', defaultWealth: 5000, description: 'Land owners, investors, passive income' },
  { value: 'merchant', label: 'Merchant', defaultWealth: 2000, description: 'Traders, shop owners, business people' },
  { value: 'craftsman', label: 'Craftsman', defaultWealth: 500, description: 'Skilled workers, artisans' },
  { value: 'laborer', label: 'Laborer', defaultWealth: 100, description: 'Unskilled workers, general labor' }
];

const ROLE_COLORS: Record<IntendedRole, string> = {
  wealthy: '#722ed1',
  merchant: '#1890ff',
  craftsman: '#52c41a',
  laborer: '#8c8c8c'
};

const ECONOMIC_SYSTEMS: { value: EconomicSystemType; label: string; description: string }[] = [
  { value: 'capitalist', label: 'Capitalist', description: 'Private ownership, free markets' },
  { value: 'collectivist', label: 'Collectivist', description: 'State/community ownership' },
  { value: 'feudal', label: 'Feudal', description: 'Lord/vassal relationships, land-based' }
];

const StartingLocationManager: React.FC = () => {
  const [data, setData] = useState<StartingLocationsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<StartingLocation | null>(null);
  const [isNew, setIsNew] = useState(false);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [form] = Form.useForm();

  // Reference data for dropdowns
  const [buildingTypes, setBuildingTypes] = useState<BuildingType[]>([]);
  const [commodities, setCommodities] = useState<Commodity[]>([]);
  const [characterClasses, setCharacterClasses] = useState<CharacterClass[]>([]);
  const [workerTypes, setWorkerTypes] = useState<WorkerType[]>([]);
  const [characterTraits, setCharacterTraits] = useState<CharacterTrait[]>([]);

  // Nested state for complex fields
  const [terrain, setTerrain] = useState<LocationTerrain>({
    riverEnabled: false,
    riverWidth: 80,
    riverPosition: 'none',
    forestDensity: 0.2,
    mountainsEnabled: false,
    mountainCount: 0,
    mountainPositions: [],
    groundColor: [0.4, 0.5, 0.3],
    waterColor: [0.2, 0.4, 0.7]
  });
  const [productionModifiers, setProductionModifiers] = useState<Record<string, number>>({});
  const [starterBuildings, setStarterBuildings] = useState<StarterBuilding[]>([]);
  const [starterResources, setStarterResources] = useState<StarterResource[]>([]);
  const [starterCitizens, setStarterCitizens] = useState<StarterCitizen[]>([]);

  // Phase 7: V2 fields for ownership and housing
  const [starterCitizensV2, setStarterCitizensV2] = useState<StarterCitizenV2[]>([]);
  const [starterBuildingsV2, setStarterBuildingsV2] = useState<StarterBuildingV2[]>([]);
  const [starterLandPlots, setStarterLandPlots] = useState<StarterLandPlot[]>([]);
  const [economicSystem, setEconomicSystem] = useState<EconomicSystemType>('capitalist');
  const [useV2Mode, setUseV2Mode] = useState(false);  // Toggle between legacy and V2 mode

  useEffect(() => {
    loadData();
    loadReferenceData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const locationsData = await loadStartingLocations();
      setData(locationsData);
    } catch (error) {
      message.error('Failed to load starting locations');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const loadReferenceData = async () => {
    try {
      const [btData, commData, classData, workerData, traitData] = await Promise.all([
        loadBuildingTypes(),
        loadCommodities(),
        loadCharacterClasses(),
        loadWorkerTypes(),
        loadCharacterTraits()
      ]);
      setBuildingTypes(btData.buildingTypes || []);
      setCommodities(commData.commodities || []);
      setCharacterClasses(classData.classes || []);
      setWorkerTypes(workerData.workerTypes || []);
      setCharacterTraits(traitData.traits || []);
    } catch (error) {
      console.error('Failed to load reference data:', error);
    }
  };

  const saveData = async (newData: StartingLocationsData) => {
    try {
      await saveStartingLocations(newData);
      setData(newData);
      message.success('Starting locations saved successfully');
    } catch (error) {
      message.error('Failed to save starting locations');
      console.error(error);
    }
  };

  const handleAdd = () => {
    setIsNew(true);
    setEditing(null);
    form.resetFields();

    // Reset nested state
    setTerrain({
      riverEnabled: false,
      riverWidth: 80,
      riverPosition: 'none',
      forestDensity: 0.2,
      mountainsEnabled: false,
      mountainCount: 0,
      mountainPositions: [],
      groundColor: [0.4, 0.5, 0.3],
      waterColor: [0.2, 0.4, 0.7]
    });
    setProductionModifiers({});
    setStarterBuildings([]);
    setStarterResources([]);
    setStarterCitizens([]);

    // Reset V2 fields
    setStarterCitizensV2([]);
    setStarterBuildingsV2([]);
    setStarterLandPlots([]);
    setEconomicSystem('capitalist');
    setUseV2Mode(false);

    form.setFieldsValue({
      starterGold: 1000,
      initialCount: 15
    });

    setIsModalVisible(true);
  };

  const handleEdit = (record: StartingLocation) => {
    setIsNew(false);
    setEditing(record);

    const recordAny = record as any;

    // Set form values
    form.setFieldsValue({
      id: record.id,
      name: record.name,
      icon: record.icon,
      description: record.description,
      bonus: record.bonus,
      challenge: record.challenge,
      starterGold: record.starterGold,
      initialCount: record.population?.initialCount || 15,
      startingTreasury: recordAny.startingTreasury
    });

    // Set nested state
    setTerrain(record.terrain || {
      riverEnabled: false,
      riverWidth: 80,
      riverPosition: 'none',
      forestDensity: 0.2,
      mountainsEnabled: false,
      mountainCount: 0,
      mountainPositions: [],
      groundColor: [0.4, 0.5, 0.3],
      waterColor: [0.2, 0.4, 0.7]
    });
    setProductionModifiers(record.productionModifiers || {});
    setStarterResources(record.starterResources || []);

    // Detect data format: Check if starterCitizens at root has V2-style fields (intendedRole, startingWealth)
    const rootCitizens = recordAny.starterCitizens || [];
    const rootBuildings = record.starterBuildings || [];
    const hasV2StyleCitizens = rootCitizens.length > 0 && rootCitizens[0]?.intendedRole !== undefined;
    const hasV2StyleBuildings = rootBuildings.length > 0 && (
      rootBuildings[0]?.ownerCitizenIndex !== undefined ||
      rootBuildings[0]?.initialOccupants !== undefined
    );
    const hasLandPlots = (recordAny.starterLandPlots?.length > 0);
    const hasEconomicSystem = recordAny.economicSystem !== undefined;

    // Determine if this is V2 format data
    const isV2Format = hasV2StyleCitizens || hasV2StyleBuildings || hasLandPlots || hasEconomicSystem;

    if (isV2Format) {
      // Load as V2 data - citizens are at root with V2 fields
      setStarterCitizensV2(rootCitizens.map((c: any) => ({
        name: c.name,
        vocationId: c.vocation || c.vocationId,
        intendedRole: c.intendedRole || 'laborer',
        startingWealth: c.startingWealth || 0,
        traitIds: c.traitIds || [],
        housingBuildingIndex: c.housingBuildingIndex,
        workplaceIndex: c.workplaceIndex,
        familyRelation: c.familyRelation
      })));

      // Load buildings as V2
      setStarterBuildingsV2(rootBuildings.map((b: any) => ({
        typeId: b.typeId,
        x: b.x,
        y: b.y,
        autoAssignRecipe: b.autoAssignRecipe,
        ownerCitizenIndex: b.ownerCitizenIndex,
        initialOccupants: b.initialOccupants || [],
        rentRate: b.rentRate
      })));

      setStarterLandPlots(recordAny.starterLandPlots || []);
      setEconomicSystem(recordAny.economicSystem || 'capitalist');
      setUseV2Mode(true);

      // Clear legacy data
      setStarterBuildings([]);
      setStarterCitizens([]);
    } else {
      // Load as legacy data
      setStarterBuildings(rootBuildings);

      // Handle migration from old traitId to new traitIds format
      const citizens = (record.population?.starterCitizens || []).map(c => ({
        ...c,
        traitIds: c.traitIds || ((c as any).traitId ? [(c as any).traitId] : [])
      }));
      setStarterCitizens(citizens);

      // Clear V2 data
      setStarterCitizensV2([]);
      setStarterBuildingsV2([]);
      setStarterLandPlots([]);
      setEconomicSystem('capitalist');
      setUseV2Mode(false);
    }

    setIsModalVisible(true);
  };

  const handleDelete = (record: StartingLocation) => {
    if (!data) return;

    const newData: StartingLocationsData = {
      ...data,
      locations: data.locations.filter(l => l.id !== record.id),
    };

    saveData(newData);
  };

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data) return;

      // Build the location object based on mode
      let newLocation: any;

      if (useV2Mode) {
        // V2 format: starterCitizens and starterBuildings at root level with V2 fields
        newLocation = {
          id: values.id,
          name: values.name,
          icon: values.icon || '*',
          description: values.description || '',
          bonus: values.bonus || '',
          challenge: values.challenge || '',
          terrain: terrain,
          productionModifiers: productionModifiers,
          starterBuildings: starterBuildingsV2.map(b => ({
            typeId: b.typeId,
            x: b.x,
            y: b.y,
            autoAssignRecipe: b.autoAssignRecipe,
            ...(b.ownerCitizenIndex !== undefined && { ownerCitizenIndex: b.ownerCitizenIndex }),
            ...(b.initialOccupants && b.initialOccupants.length > 0 && { initialOccupants: b.initialOccupants }),
            ...(b.rentRate !== undefined && { rentRate: b.rentRate })
          })),
          starterResources: starterResources,
          starterGold: values.starterGold || 1000,
          startingTreasury: values.startingTreasury || 0,
          economicSystem: economicSystem,
          starterCitizens: starterCitizensV2.map(c => ({
            name: c.name,
            startingWealth: c.startingWealth || 0,
            intendedRole: c.intendedRole,
            vocation: c.vocationId,
            ...(c.workplaceIndex !== undefined && { workplaceIndex: c.workplaceIndex }),
            ...(c.housingBuildingIndex !== undefined && { housingBuildingIndex: c.housingBuildingIndex }),
            ...(c.familyRelation && { familyRelation: c.familyRelation }),
            ...(c.traitIds && c.traitIds.length > 0 && { traitIds: c.traitIds })
          })),
          ...(starterLandPlots.length > 0 && { starterLandPlots: starterLandPlots }),
          population: {
            initialCount: starterCitizensV2.length || values.initialCount || 15,
            classDistribution: {}
          }
        };
      } else {
        // Legacy format
        newLocation = {
          id: values.id,
          name: values.name,
          icon: values.icon || '*',
          description: values.description || '',
          bonus: values.bonus || '',
          challenge: values.challenge || '',
          terrain: terrain,
          productionModifiers: productionModifiers,
          starterBuildings: starterBuildings,
          starterResources: starterResources,
          starterGold: values.starterGold || 1000,
          population: {
            initialCount: values.initialCount || 15,
            classDistribution: {},
            ...(starterCitizens.length > 0 && { starterCitizens: starterCitizens })
          }
        };
      }

      let newLocations: StartingLocation[];

      if (isNew) {
        // Check for duplicate ID
        if (data.locations.find(l => l.id === newLocation.id)) {
          message.error('A location with this ID already exists');
          return;
        }
        newLocations = [...data.locations, newLocation];
      } else if (editing) {
        newLocations = data.locations.map(l =>
          l.id === editing.id ? newLocation : l
        );
      } else {
        return;
      }

      const newData: StartingLocationsData = {
        ...data,
        locations: newLocations,
      };

      await saveData(newData);
      setIsModalVisible(false);
      form.resetFields();
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  // Mountain position handlers
  const addMountainPosition = () => {
    const newPos: MountainPosition = { x: 500, y: 500, width: 150, height: 100 };
    setTerrain({
      ...terrain,
      mountainPositions: [...terrain.mountainPositions, newPos],
      mountainCount: terrain.mountainPositions.length + 1
    });
  };

  const removeMountainPosition = (index: number) => {
    const newPositions = terrain.mountainPositions.filter((_, i) => i !== index);
    setTerrain({
      ...terrain,
      mountainPositions: newPositions,
      mountainCount: newPositions.length
    });
  };

  const updateMountainPosition = (index: number, field: keyof MountainPosition, value: number) => {
    const newPositions = [...terrain.mountainPositions];
    newPositions[index] = { ...newPositions[index], [field]: value };
    setTerrain({ ...terrain, mountainPositions: newPositions });
  };

  // Starter building handlers
  const addStarterBuilding = () => {
    setStarterBuildings([...starterBuildings, {
      typeId: buildingTypes[0]?.id || 'farm',
      x: 100,
      y: 100,
      autoAssignRecipe: true
    }]);
  };

  const removeStarterBuilding = (index: number) => {
    setStarterBuildings(starterBuildings.filter((_, i) => i !== index));
  };

  const updateStarterBuilding = (index: number, field: keyof StarterBuilding, value: any) => {
    const newBuildings = [...starterBuildings];
    newBuildings[index] = { ...newBuildings[index], [field]: value };
    setStarterBuildings(newBuildings);
  };

  // Starter resource handlers
  const addStarterResource = () => {
    setStarterResources([...starterResources, {
      commodityId: commodities[0]?.id || 'wheat',
      quantity: 50
    }]);
  };

  const removeStarterResource = (index: number) => {
    setStarterResources(starterResources.filter((_, i) => i !== index));
  };

  const updateStarterResource = (index: number, field: keyof StarterResource, value: any) => {
    const newResources = [...starterResources];
    newResources[index] = { ...newResources[index], [field]: value };
    setStarterResources(newResources);
  };

  // Production modifier handlers
  const addProductionModifier = () => {
    setProductionModifiers({ ...productionModifiers, new_category: 1.0 });
  };

  const removeProductionModifier = (key: string) => {
    const newModifiers = { ...productionModifiers };
    delete newModifiers[key];
    setProductionModifiers(newModifiers);
  };

  const updateProductionModifier = (oldKey: string, newKey: string, value: number) => {
    const newModifiers = { ...productionModifiers };
    if (oldKey !== newKey) {
      delete newModifiers[oldKey];
    }
    newModifiers[newKey] = value;
    setProductionModifiers(newModifiers);
  };

  // Starter citizen handlers
  const addStarterCitizen = () => {
    setStarterCitizens([...starterCitizens, {
      classId: characterClasses[0]?.id || 'middle',
      vocationId: workerTypes[0]?.id || 'worker',
      traitIds: []
    }]);
  };

  const removeStarterCitizen = (index: number) => {
    setStarterCitizens(starterCitizens.filter((_, i) => i !== index));
  };

  const updateStarterCitizen = (index: number, field: keyof StarterCitizen, value: any) => {
    const newCitizens = [...starterCitizens];
    newCitizens[index] = { ...newCitizens[index], [field]: value };
    setStarterCitizens(newCitizens);
  };

  // ========================================
  // V2 Handlers - Starter Citizens with Role/Wealth
  // ========================================

  const addStarterCitizenV2 = () => {
    const defaultRole = INTENDED_ROLES[2]; // craftsman
    setStarterCitizensV2([...starterCitizensV2, {
      vocationId: workerTypes[0]?.id || 'worker',
      intendedRole: defaultRole.value,
      startingWealth: defaultRole.defaultWealth,
      traitIds: []
    }]);
  };

  const removeStarterCitizenV2 = (index: number) => {
    setStarterCitizensV2(starterCitizensV2.filter((_, i) => i !== index));
  };

  const updateStarterCitizenV2 = (index: number, field: keyof StarterCitizenV2, value: any) => {
    const newCitizens = [...starterCitizensV2];
    newCitizens[index] = { ...newCitizens[index], [field]: value };

    // Auto-update wealth when role changes
    if (field === 'intendedRole') {
      const roleInfo = INTENDED_ROLES.find(r => r.value === value);
      if (roleInfo && !newCitizens[index].startingWealth) {
        newCitizens[index].startingWealth = roleInfo.defaultWealth;
      }
    }

    setStarterCitizensV2(newCitizens);
  };

  // ========================================
  // V2 Handlers - Starter Buildings with Ownership
  // ========================================

  const addStarterBuildingV2 = () => {
    setStarterBuildingsV2([...starterBuildingsV2, {
      typeId: buildingTypes[0]?.id || 'farm',
      x: 100,
      y: 100,
      autoAssignRecipe: true,
      ownerCitizenIndex: undefined,  // Town-owned by default
      initialOccupants: []
    }]);
  };

  const removeStarterBuildingV2 = (index: number) => {
    setStarterBuildingsV2(starterBuildingsV2.filter((_, i) => i !== index));
  };

  const updateStarterBuildingV2 = (index: number, field: keyof StarterBuildingV2, value: any) => {
    const newBuildings = [...starterBuildingsV2];
    newBuildings[index] = { ...newBuildings[index], [field]: value };
    setStarterBuildingsV2(newBuildings);
  };

  // ========================================
  // V2 Handlers - Starter Land Plots
  // ========================================

  const addStarterLandPlot = () => {
    setStarterLandPlots([...starterLandPlots, {
      gridX: 0,
      gridY: 0,
      ownerCitizenIndex: undefined  // Town-owned
    }]);
  };

  const removeStarterLandPlot = (index: number) => {
    setStarterLandPlots(starterLandPlots.filter((_, i) => i !== index));
  };

  const updateStarterLandPlot = (index: number, field: keyof StarterLandPlot, value: any) => {
    const newPlots = [...starterLandPlots];
    newPlots[index] = { ...newPlots[index], [field]: value };
    setStarterLandPlots(newPlots);
  };

  const columns = [
    {
      title: 'Icon',
      dataIndex: 'icon',
      key: 'icon',
      width: 60,
      render: (icon: string) => <span style={{ fontSize: 20 }}>{icon}</span>,
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
      title: 'Bonus',
      dataIndex: 'bonus',
      key: 'bonus',
      width: 200,
      render: (bonus: string) => <Tag color="green">{bonus}</Tag>,
    },
    {
      title: 'Challenge',
      dataIndex: 'challenge',
      key: 'challenge',
      width: 200,
      render: (challenge: string) => <Tag color="orange">{challenge}</Tag>,
    },
    {
      title: 'Terrain',
      key: 'terrain',
      width: 180,
      render: (_: any, record: StartingLocation) => (
        <Space size={4} wrap>
          {record.terrain?.riverEnabled && <Tag color="blue">River</Tag>}
          {record.terrain?.mountainsEnabled && <Tag color="default">Mountains ({record.terrain.mountainCount})</Tag>}
          <Tag color="green">Forest: {Math.round((record.terrain?.forestDensity || 0) * 100)}%</Tag>
        </Space>
      ),
    },
    {
      title: 'Pop',
      key: 'population',
      width: 60,
      render: (_: any, record: StartingLocation) => record.population?.initialCount || '-',
    },
    {
      title: 'Gold',
      dataIndex: 'starterGold',
      key: 'starterGold',
      width: 80,
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 100,
      fixed: 'right' as const,
      render: (_: any, record: StartingLocation) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEdit(record)}
          />
          <Popconfirm
            title="Delete this location?"
            onConfirm={() => handleDelete(record)}
            okText="Yes"
            cancelText="No"
          >
            <Button type="link" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  if (!data) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <Card
        title={`Starting Locations (${data.locations.length})`}
        extra={
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAdd}
          >
            Add Location
          </Button>
        }
      >
        <Table
          columns={columns}
          dataSource={data.locations}
          rowKey="id"
          loading={loading}
          scroll={{ x: 1200 }}
          pagination={{ pageSize: 10 }}
        />
      </Card>

      <Modal
        title={isNew ? 'Add Starting Location' : 'Edit Starting Location'}
        open={isModalVisible}
        onOk={handleModalOk}
        onCancel={() => {
          setIsModalVisible(false);
          form.resetFields();
        }}
        width={1000}
        style={{ top: 20 }}
      >
        <Tabs defaultActiveKey="basic">
          <TabPane tab="Basic Info" key="basic">
            <Form form={form} layout="vertical">
              <Row gutter={16}>
                <Col span={8}>
                  <Form.Item
                    name="id"
                    label="ID"
                    rules={[{ required: true, message: 'Please input the ID!' }]}
                  >
                    <Input placeholder="e.g., river_valley" disabled={!isNew} />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="name"
                    label="Name"
                    rules={[{ required: true, message: 'Please input the name!' }]}
                  >
                    <Input placeholder="e.g., River Valley" />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="icon"
                    label="Icon"
                    rules={[{ required: true, message: 'Please input the icon!' }]}
                  >
                    <Input placeholder="e.g., ~" maxLength={2} />
                  </Form.Item>
                </Col>
              </Row>

              <Form.Item
                name="description"
                label="Description"
              >
                <TextArea rows={2} placeholder="Describe this starting location..." />
              </Form.Item>

              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    name="bonus"
                    label="Bonus"
                  >
                    <Input placeholder="e.g., +20% fishing, +water access" />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    name="challenge"
                    label="Challenge"
                  >
                    <Input placeholder="e.g., -15% farming space" />
                  </Form.Item>
                </Col>
              </Row>

              <Row gutter={16}>
                <Col span={8}>
                  <Form.Item
                    name="starterGold"
                    label="Starter Gold"
                  >
                    <InputNumber min={0} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    name="initialCount"
                    label="Initial Population"
                  >
                    <InputNumber min={1} max={100} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
              </Row>

              {useV2Mode && (
                <>
                  <Divider orientation="left">V2 Economic Settings</Divider>
                  <Row gutter={16}>
                    <Col span={8}>
                      <Form.Item label="Economic System">
                        <Select
                          value={economicSystem}
                          onChange={setEconomicSystem}
                          style={{ width: '100%' }}
                        >
                          {ECONOMIC_SYSTEMS.map(sys => (
                            <Select.Option key={sys.value} value={sys.value}>
                              <Tooltip title={sys.description}>
                                {sys.label}
                              </Tooltip>
                            </Select.Option>
                          ))}
                        </Select>
                      </Form.Item>
                    </Col>
                    <Col span={8}>
                      <Form.Item
                        name="startingTreasury"
                        label="Town Starting Treasury"
                        tooltip="Initial gold in the town treasury (for rent collection, wages, etc.)"
                      >
                        <InputNumber min={0} style={{ width: '100%' }} placeholder="0" />
                      </Form.Item>
                    </Col>
                  </Row>
                </>
              )}
            </Form>
          </TabPane>

          <TabPane tab="Terrain" key="terrain">
            <Divider orientation="left">River Settings</Divider>
            <Row gutter={16} align="middle">
              <Col span={4}>
                <span>River Enabled:</span>
              </Col>
              <Col span={4}>
                <Switch
                  checked={terrain.riverEnabled}
                  onChange={(checked) => setTerrain({ ...terrain, riverEnabled: checked, riverPosition: checked ? 'center' : 'none' })}
                />
              </Col>
              <Col span={6}>
                <span>Position:</span>
                <Select
                  style={{ width: 120, marginLeft: 8 }}
                  value={terrain.riverPosition}
                  onChange={(value) => setTerrain({ ...terrain, riverPosition: value })}
                  disabled={!terrain.riverEnabled}
                >
                  {RIVER_POSITIONS.map(pos => (
                    <Select.Option key={pos} value={pos}>{pos}</Select.Option>
                  ))}
                </Select>
              </Col>
              <Col span={6}>
                <span>Width:</span>
                <InputNumber
                  style={{ width: 80, marginLeft: 8 }}
                  min={40}
                  max={200}
                  value={terrain.riverWidth}
                  onChange={(value) => setTerrain({ ...terrain, riverWidth: value || 80 })}
                  disabled={!terrain.riverEnabled}
                />
              </Col>
            </Row>

            <Divider orientation="left">Forest Settings</Divider>
            <Row gutter={16} align="middle">
              <Col span={8}>
                <span>Forest Density (0-1):</span>
                <InputNumber
                  style={{ width: 80, marginLeft: 8 }}
                  min={0}
                  max={1}
                  step={0.05}
                  value={terrain.forestDensity}
                  onChange={(value) => setTerrain({ ...terrain, forestDensity: value || 0 })}
                />
              </Col>
            </Row>

            <Divider orientation="left">Mountain Settings</Divider>
            <Row gutter={16} align="middle" style={{ marginBottom: 16 }}>
              <Col span={4}>
                <span>Mountains:</span>
              </Col>
              <Col span={4}>
                <Switch
                  checked={terrain.mountainsEnabled}
                  onChange={(checked) => setTerrain({ ...terrain, mountainsEnabled: checked })}
                />
              </Col>
              <Col span={8}>
                <Button
                  type="dashed"
                  icon={<PlusOutlined />}
                  onClick={addMountainPosition}
                  disabled={!terrain.mountainsEnabled}
                >
                  Add Mountain
                </Button>
              </Col>
            </Row>

            {terrain.mountainPositions.map((pos, index) => (
              <Row key={index} gutter={8} style={{ marginBottom: 8 }} align="middle">
                <Col span={5}>
                  <span>X:</span>
                  <InputNumber
                    size="small"
                    style={{ width: 80, marginLeft: 4 }}
                    value={pos.x}
                    onChange={(v) => updateMountainPosition(index, 'x', v || 0)}
                  />
                </Col>
                <Col span={5}>
                  <span>Y:</span>
                  <InputNumber
                    size="small"
                    style={{ width: 80, marginLeft: 4 }}
                    value={pos.y}
                    onChange={(v) => updateMountainPosition(index, 'y', v || 0)}
                  />
                </Col>
                <Col span={5}>
                  <span>W:</span>
                  <InputNumber
                    size="small"
                    style={{ width: 60, marginLeft: 4 }}
                    value={pos.width}
                    onChange={(v) => updateMountainPosition(index, 'width', v || 100)}
                  />
                </Col>
                <Col span={5}>
                  <span>H:</span>
                  <InputNumber
                    size="small"
                    style={{ width: 60, marginLeft: 4 }}
                    value={pos.height}
                    onChange={(v) => updateMountainPosition(index, 'height', v || 80)}
                  />
                </Col>
                <Col span={4}>
                  <Button
                    type="link"
                    danger
                    icon={<MinusCircleOutlined />}
                    onClick={() => removeMountainPosition(index)}
                  />
                </Col>
              </Row>
            ))}

            <Divider orientation="left">Colors (RGB 0-1)</Divider>
            <Row gutter={16}>
              <Col span={12}>
                <span>Ground Color:</span>
                <Space style={{ marginLeft: 8 }}>
                  <InputNumber
                    size="small"
                    style={{ width: 60 }}
                    min={0}
                    max={1}
                    step={0.05}
                    value={terrain.groundColor[0]}
                    onChange={(v) => setTerrain({ ...terrain, groundColor: [v || 0, terrain.groundColor[1], terrain.groundColor[2]] })}
                  />
                  <InputNumber
                    size="small"
                    style={{ width: 60 }}
                    min={0}
                    max={1}
                    step={0.05}
                    value={terrain.groundColor[1]}
                    onChange={(v) => setTerrain({ ...terrain, groundColor: [terrain.groundColor[0], v || 0, terrain.groundColor[2]] })}
                  />
                  <InputNumber
                    size="small"
                    style={{ width: 60 }}
                    min={0}
                    max={1}
                    step={0.05}
                    value={terrain.groundColor[2]}
                    onChange={(v) => setTerrain({ ...terrain, groundColor: [terrain.groundColor[0], terrain.groundColor[1], v || 0] })}
                  />
                  <div
                    style={{
                      width: 24,
                      height: 24,
                      backgroundColor: `rgb(${terrain.groundColor[0] * 255}, ${terrain.groundColor[1] * 255}, ${terrain.groundColor[2] * 255})`,
                      border: '1px solid #ddd',
                      borderRadius: 4
                    }}
                  />
                </Space>
              </Col>
              <Col span={12}>
                <span>Water Color:</span>
                <Space style={{ marginLeft: 8 }}>
                  <InputNumber
                    size="small"
                    style={{ width: 60 }}
                    min={0}
                    max={1}
                    step={0.05}
                    value={terrain.waterColor[0]}
                    onChange={(v) => setTerrain({ ...terrain, waterColor: [v || 0, terrain.waterColor[1], terrain.waterColor[2]] })}
                  />
                  <InputNumber
                    size="small"
                    style={{ width: 60 }}
                    min={0}
                    max={1}
                    step={0.05}
                    value={terrain.waterColor[1]}
                    onChange={(v) => setTerrain({ ...terrain, waterColor: [terrain.waterColor[0], v || 0, terrain.waterColor[2]] })}
                  />
                  <InputNumber
                    size="small"
                    style={{ width: 60 }}
                    min={0}
                    max={1}
                    step={0.05}
                    value={terrain.waterColor[2]}
                    onChange={(v) => setTerrain({ ...terrain, waterColor: [terrain.waterColor[0], terrain.waterColor[1], v || 0] })}
                  />
                  <div
                    style={{
                      width: 24,
                      height: 24,
                      backgroundColor: `rgb(${terrain.waterColor[0] * 255}, ${terrain.waterColor[1] * 255}, ${terrain.waterColor[2] * 255})`,
                      border: '1px solid #ddd',
                      borderRadius: 4
                    }}
                  />
                </Space>
              </Col>
            </Row>
          </TabPane>

          <TabPane tab="Production Modifiers" key="modifiers">
            <Button
              type="dashed"
              icon={<PlusOutlined />}
              onClick={addProductionModifier}
              style={{ marginBottom: 16 }}
            >
              Add Modifier
            </Button>

            {Object.entries(productionModifiers).map(([key, value]) => (
              <Row key={key} gutter={16} style={{ marginBottom: 8 }} align="middle">
                <Col span={10}>
                  <Input
                    value={key}
                    placeholder="Category (e.g., farming, mining)"
                    onChange={(e) => updateProductionModifier(key, e.target.value, value)}
                  />
                </Col>
                <Col span={8}>
                  <InputNumber
                    style={{ width: '100%' }}
                    min={0}
                    max={5}
                    step={0.05}
                    value={value}
                    onChange={(v) => updateProductionModifier(key, key, v || 1)}
                    addonAfter="x"
                  />
                </Col>
                <Col span={4}>
                  <Button
                    type="link"
                    danger
                    icon={<MinusCircleOutlined />}
                    onClick={() => removeProductionModifier(key)}
                  />
                </Col>
              </Row>
            ))}

            <div style={{ marginTop: 16, color: '#888' }}>
              <p>Modifiers: 1.0 = normal, 1.2 = +20%, 0.8 = -20%</p>
              <p>Common categories: farming, mining, fishing, lumber, hunting, trade, water_access</p>
            </div>
          </TabPane>

          <TabPane tab="Starter Buildings" key="buildings">
            {useV2Mode ? (
              <>
                <Alert
                  message="V2 Building Mode"
                  description="Configure building ownership and initial occupants. Buildings can be owned by citizens (by index) or the town (leave owner blank)."
                  type="info"
                  showIcon
                  icon={<InfoCircleOutlined />}
                  style={{ marginBottom: 16 }}
                />

                <Button
                  type="dashed"
                  icon={<PlusOutlined />}
                  onClick={addStarterBuildingV2}
                  style={{ marginBottom: 16 }}
                >
                  Add Building
                </Button>

                {starterBuildingsV2.map((building, index) => {
                  const buildingType = buildingTypes.find(bt => bt.id === building.typeId);
                  const isHousing = buildingType?.category === 'housing';

                  return (
                    <Card
                      key={index}
                      size="small"
                      style={{ marginBottom: 12 }}
                      title={
                        <Space>
                          <span style={{ color: '#888' }}>#{index + 1}</span>
                          <Tag color={isHousing ? 'blue' : 'default'}>
                            {isHousing ? <HomeOutlined /> : null} {building.typeId}
                          </Tag>
                        </Space>
                      }
                      extra={
                        <Button
                          type="link"
                          danger
                          icon={<MinusCircleOutlined />}
                          onClick={() => removeStarterBuildingV2(index)}
                        />
                      }
                    >
                      <Row gutter={16}>
                        <Col span={8}>
                          <div style={{ marginBottom: 8 }}>
                            <span style={{ color: '#888', fontSize: 12 }}>Building Type:</span>
                          </div>
                          <Select
                            style={{ width: '100%' }}
                            value={building.typeId}
                            onChange={(value) => updateStarterBuildingV2(index, 'typeId', value)}
                            showSearch
                            optionFilterProp="children"
                            filterOption={(input, option) =>
                              (option?.children as unknown as string)?.toLowerCase().includes(input.toLowerCase())
                            }
                          >
                            {buildingTypes.map(bt => (
                              <Select.Option key={bt.id} value={bt.id}>
                                {bt.category === 'housing' && <HomeOutlined style={{ marginRight: 4 }} />}
                                {bt.id}
                              </Select.Option>
                            ))}
                          </Select>
                        </Col>
                        <Col span={4}>
                          <div style={{ marginBottom: 8 }}>
                            <span style={{ color: '#888', fontSize: 12 }}>X:</span>
                          </div>
                          <InputNumber
                            style={{ width: '100%' }}
                            value={building.x}
                            onChange={(v) => updateStarterBuildingV2(index, 'x', v || 100)}
                          />
                        </Col>
                        <Col span={4}>
                          <div style={{ marginBottom: 8 }}>
                            <span style={{ color: '#888', fontSize: 12 }}>Y:</span>
                          </div>
                          <InputNumber
                            style={{ width: '100%' }}
                            value={building.y}
                            onChange={(v) => updateStarterBuildingV2(index, 'y', v || 100)}
                          />
                        </Col>
                        <Col span={8}>
                          <div style={{ marginBottom: 8 }}>
                            <span style={{ color: '#888', fontSize: 12 }}>Owner:</span>
                          </div>
                          <Tooltip title="Citizen index who owns this building (leave blank for town ownership)">
                            <Select
                              style={{ width: '100%' }}
                              value={building.ownerCitizenIndex}
                              onChange={(value) => updateStarterBuildingV2(index, 'ownerCitizenIndex', value)}
                              placeholder="Town-owned"
                              allowClear
                            >
                              {starterCitizensV2.map((c, ci) => (
                                <Select.Option key={ci} value={ci}>
                                  <Tag color={ROLE_COLORS[c.intendedRole]}>#{ci + 1}</Tag>
                                  {c.name || c.intendedRole} ({c.vocationId})
                                </Select.Option>
                              ))}
                            </Select>
                          </Tooltip>
                        </Col>
                      </Row>

                      <Row gutter={16} style={{ marginTop: 12 }}>
                        <Col span={8}>
                          <Space>
                            <Switch
                              checked={building.autoAssignRecipe}
                              onChange={(checked) => updateStarterBuildingV2(index, 'autoAssignRecipe', checked)}
                            />
                            <span>Auto Recipe</span>
                          </Space>
                        </Col>

                        {isHousing && (
                          <>
                            <Col span={8}>
                              <div style={{ marginBottom: 8 }}>
                                <span style={{ color: '#888', fontSize: 12 }}>Rent Rate:</span>
                              </div>
                              <InputNumber
                                style={{ width: '100%' }}
                                value={building.rentRate}
                                onChange={(v) => updateStarterBuildingV2(index, 'rentRate', v)}
                                min={0}
                                placeholder="Default"
                                addonAfter="gold"
                              />
                            </Col>
                            <Col span={8}>
                              <div style={{ marginBottom: 8 }}>
                                <span style={{ color: '#888', fontSize: 12 }}>Initial Occupants:</span>
                              </div>
                              <Tooltip title="Citizen indices who will live here initially">
                                <Select
                                  mode="multiple"
                                  style={{ width: '100%' }}
                                  value={building.initialOccupants || []}
                                  onChange={(values) => updateStarterBuildingV2(index, 'initialOccupants', values)}
                                  placeholder="None"
                                  allowClear
                                  maxTagCount={2}
                                >
                                  {starterCitizensV2.map((c, ci) => (
                                    <Select.Option key={ci} value={ci}>
                                      #{ci + 1} {c.intendedRole}
                                    </Select.Option>
                                  ))}
                                </Select>
                              </Tooltip>
                            </Col>
                          </>
                        )}
                      </Row>
                    </Card>
                  );
                })}

                <Divider />
                <Row gutter={16}>
                  <Col span={8}>
                    <div><strong>Total Buildings:</strong> {starterBuildingsV2.length}</div>
                  </Col>
                  <Col span={8}>
                    <div>
                      <strong>Housing:</strong>{' '}
                      <Tag color="blue">
                        {starterBuildingsV2.filter(b => buildingTypes.find(bt => bt.id === b.typeId)?.category === 'housing').length}
                      </Tag>
                    </div>
                  </Col>
                  <Col span={8}>
                    <div>
                      <strong>Citizen-owned:</strong>{' '}
                      <Tag color="green">
                        {starterBuildingsV2.filter(b => b.ownerCitizenIndex !== undefined).length}
                      </Tag>
                    </div>
                  </Col>
                </Row>
              </>
            ) : (
              <>
                <Button
                  type="dashed"
                  icon={<PlusOutlined />}
                  onClick={addStarterBuilding}
                  style={{ marginBottom: 16 }}
                >
                  Add Building
                </Button>

                {starterBuildings.map((building, index) => (
                  <Row key={index} gutter={8} style={{ marginBottom: 8 }} align="middle">
                    <Col span={8}>
                      <Select
                        style={{ width: '100%' }}
                        value={building.typeId}
                        onChange={(value) => updateStarterBuilding(index, 'typeId', value)}
                        showSearch
                        optionFilterProp="children"
                        filterOption={(input, option) =>
                          (option?.children as unknown as string)?.toLowerCase().includes(input.toLowerCase())
                        }
                      >
                        {buildingTypes.map(bt => (
                          <Select.Option key={bt.id} value={bt.id}>{bt.id}</Select.Option>
                        ))}
                      </Select>
                    </Col>
                    <Col span={4}>
                      <InputNumber
                        style={{ width: '100%' }}
                        placeholder="X"
                        value={building.x}
                        onChange={(v) => updateStarterBuilding(index, 'x', v || 100)}
                      />
                    </Col>
                    <Col span={4}>
                      <InputNumber
                        style={{ width: '100%' }}
                        placeholder="Y"
                        value={building.y}
                        onChange={(v) => updateStarterBuilding(index, 'y', v || 100)}
                      />
                    </Col>
                    <Col span={5}>
                      <Switch
                        checked={building.autoAssignRecipe}
                        onChange={(checked) => updateStarterBuilding(index, 'autoAssignRecipe', checked)}
                      />
                      <span style={{ marginLeft: 8 }}>Auto Recipe</span>
                    </Col>
                    <Col span={3}>
                      <Button
                        type="link"
                        danger
                        icon={<MinusCircleOutlined />}
                        onClick={() => removeStarterBuilding(index)}
                      />
                    </Col>
                  </Row>
                ))}

                <div style={{ marginTop: 16, color: '#888' }}>
                  <p>Available building types: {buildingTypes.slice(0, 10).map(bt => bt.id).join(', ')}...</p>
                </div>
              </>
            )}
          </TabPane>

          <TabPane tab="Starter Resources" key="resources">
            <Button
              type="dashed"
              icon={<PlusOutlined />}
              onClick={addStarterResource}
              style={{ marginBottom: 16 }}
            >
              Add Resource
            </Button>

            {starterResources.map((resource, index) => (
              <Row key={index} gutter={16} style={{ marginBottom: 8 }} align="middle">
                <Col span={12}>
                  <Select
                    style={{ width: '100%' }}
                    value={resource.commodityId}
                    onChange={(value) => updateStarterResource(index, 'commodityId', value)}
                    showSearch
                    optionFilterProp="children"
                    filterOption={(input, option) =>
                      (option?.children as unknown as string)?.toLowerCase().includes(input.toLowerCase())
                    }
                  >
                    {commodities.map(c => (
                      <Select.Option key={c.id} value={c.id}>{c.id}</Select.Option>
                    ))}
                  </Select>
                </Col>
                <Col span={8}>
                  <InputNumber
                    style={{ width: '100%' }}
                    min={0}
                    value={resource.quantity}
                    onChange={(v) => updateStarterResource(index, 'quantity', v || 0)}
                    addonAfter="units"
                  />
                </Col>
                <Col span={4}>
                  <Button
                    type="link"
                    danger
                    icon={<MinusCircleOutlined />}
                    onClick={() => removeStarterResource(index)}
                  />
                </Col>
              </Row>
            ))}

            <div style={{ marginTop: 16, color: '#888' }}>
              <p>Available commodities: {commodities.slice(0, 10).map(c => c.id).join(', ')}...</p>
            </div>
          </TabPane>

          <TabPane tab="Population" key="population">
            <Alert
              message="Citizen Definition Mode"
              description={
                <Space direction="vertical">
                  <span>
                    <strong>V2 Mode (Emergent Classes):</strong> Define citizens with intended role and starting wealth.
                    Their social class emerges from economic activity.
                  </span>
                  <span>
                    <strong>Legacy Mode:</strong> Define citizens with fixed class assignment (deprecated).
                  </span>
                </Space>
              }
              type="info"
              showIcon
              icon={<InfoCircleOutlined />}
              style={{ marginBottom: 16 }}
            />

            <Row style={{ marginBottom: 16 }}>
              <Col span={12}>
                <Space>
                  <span>Mode:</span>
                  <Switch
                    checked={useV2Mode}
                    onChange={setUseV2Mode}
                    checkedChildren="V2 (Emergent)"
                    unCheckedChildren="Legacy"
                  />
                </Space>
              </Col>
            </Row>

            {useV2Mode ? (
              <>
                <Divider orientation="left">
                  <Space>
                    <UserOutlined />
                    Starter Citizens (V2 - Role/Wealth)
                  </Space>
                </Divider>

                <Button
                  type="dashed"
                  icon={<PlusOutlined />}
                  onClick={addStarterCitizenV2}
                  style={{ marginBottom: 16 }}
                >
                  Add Citizen
                </Button>

                {starterCitizensV2.map((citizen, index) => (
                  <Card
                    key={index}
                    size="small"
                    style={{ marginBottom: 12 }}
                    title={
                      <Space>
                        <span style={{ color: '#888' }}>#{index + 1}</span>
                        <Tag color={ROLE_COLORS[citizen.intendedRole]}>{citizen.intendedRole}</Tag>
                        {citizen.name && <span>{citizen.name}</span>}
                      </Space>
                    }
                    extra={
                      <Button
                        type="link"
                        danger
                        icon={<MinusCircleOutlined />}
                        onClick={() => removeStarterCitizenV2(index)}
                      />
                    }
                  >
                    <Row gutter={16}>
                      <Col span={6}>
                        <div style={{ marginBottom: 4, color: '#888', fontSize: 12 }}>Name:</div>
                        <Input
                          value={citizen.name}
                          onChange={(e) => updateStarterCitizenV2(index, 'name', e.target.value)}
                          placeholder="Citizen name"
                        />
                      </Col>
                      <Col span={4}>
                        <div style={{ marginBottom: 4, color: '#888', fontSize: 12 }}>Role:</div>
                        <Select
                          style={{ width: '100%' }}
                          value={citizen.intendedRole}
                          onChange={(value) => updateStarterCitizenV2(index, 'intendedRole', value)}
                          placeholder="Role"
                        >
                          {INTENDED_ROLES.map(role => (
                            <Select.Option key={role.value} value={role.value}>
                              <Tag color={ROLE_COLORS[role.value]}>{role.label}</Tag>
                            </Select.Option>
                          ))}
                        </Select>
                      </Col>
                      <Col span={4}>
                        <div style={{ marginBottom: 4, color: '#888', fontSize: 12 }}>Wealth:</div>
                        <InputNumber
                          style={{ width: '100%' }}
                          value={citizen.startingWealth}
                          onChange={(v) => updateStarterCitizenV2(index, 'startingWealth', v || 0)}
                          min={0}
                          prefix={<DollarOutlined />}
                        />
                      </Col>
                      <Col span={5}>
                        <div style={{ marginBottom: 4, color: '#888', fontSize: 12 }}>Vocation:</div>
                        <Select
                          style={{ width: '100%' }}
                          value={citizen.vocationId}
                          onChange={(value) => updateStarterCitizenV2(index, 'vocationId', value)}
                          placeholder="Vocation"
                          showSearch
                          optionFilterProp="children"
                          filterOption={(input, option) =>
                            (option?.children as unknown as string)?.toLowerCase().includes(input.toLowerCase())
                          }
                        >
                          {workerTypes.map(wt => (
                            <Select.Option key={wt.id} value={wt.id}>{wt.name}</Select.Option>
                          ))}
                        </Select>
                      </Col>
                      <Col span={5}>
                        <div style={{ marginBottom: 4, color: '#888', fontSize: 12 }}>Traits:</div>
                        <Select
                          mode="multiple"
                          style={{ width: '100%' }}
                          value={citizen.traitIds || []}
                          onChange={(values) => updateStarterCitizenV2(index, 'traitIds', values)}
                          placeholder="Traits"
                          allowClear
                          maxTagCount={1}
                        >
                          {characterTraits.map(trait => (
                            <Select.Option key={trait.id} value={trait.id}>{trait.id}</Select.Option>
                          ))}
                        </Select>
                      </Col>
                    </Row>
                    <Row gutter={16} style={{ marginTop: 12 }}>
                      <Col span={6}>
                        <div style={{ marginBottom: 4, color: '#888', fontSize: 12 }}>Housing:</div>
                        <Select
                          style={{ width: '100%' }}
                          value={citizen.housingBuildingIndex}
                          onChange={(value) => updateStarterCitizenV2(index, 'housingBuildingIndex', value)}
                          placeholder="Housing"
                          allowClear
                        >
                          {starterBuildingsV2.map((b, bi) => {
                            const bt = buildingTypes.find(t => t.id === b.typeId);
                            if (bt?.category === 'housing') {
                              return (
                                <Select.Option key={bi} value={bi}>
                                  <HomeOutlined /> #{bi + 1} {b.typeId}
                                </Select.Option>
                              );
                            }
                            return null;
                          }).filter(Boolean)}
                        </Select>
                      </Col>
                      <Col span={6}>
                        <div style={{ marginBottom: 4, color: '#888', fontSize: 12 }}>Workplace:</div>
                        <Select
                          style={{ width: '100%' }}
                          value={citizen.workplaceIndex}
                          onChange={(value) => updateStarterCitizenV2(index, 'workplaceIndex', value)}
                          placeholder="Workplace"
                          allowClear
                        >
                          {starterBuildingsV2.map((b, bi) => {
                            const bt = buildingTypes.find(t => t.id === b.typeId);
                            if (bt?.category !== 'housing') {
                              return (
                                <Select.Option key={bi} value={bi}>
                                  #{bi + 1} {b.typeId}
                                </Select.Option>
                              );
                            }
                            return null;
                          }).filter(Boolean)}
                        </Select>
                      </Col>
                    </Row>
                  </Card>
                ))}

                <Divider />
                <Row gutter={16}>
                  <Col span={8}>
                    <div style={{ color: '#888' }}>
                      <p><strong>Citizens defined:</strong> {starterCitizensV2.length}</p>
                    </div>
                  </Col>
                  <Col span={8}>
                    <div>
                      <strong>Total Starting Wealth:</strong>{' '}
                      <Tag color="gold">
                        {starterCitizensV2.reduce((sum, c) => sum + (c.startingWealth || 0), 0).toLocaleString()} gold
                      </Tag>
                    </div>
                  </Col>
                  <Col span={8}>
                    <div>
                      <strong>By Role:</strong>{' '}
                      {INTENDED_ROLES.map(role => {
                        const count = starterCitizensV2.filter(c => c.intendedRole === role.value).length;
                        return count > 0 ? (
                          <Tag key={role.value} color={ROLE_COLORS[role.value]}>{role.label}: {count}</Tag>
                        ) : null;
                      })}
                    </div>
                  </Col>
                </Row>
              </>
            ) : (
              <>
                <Divider orientation="left">Starter Citizens (Legacy)</Divider>
                <p style={{ color: '#888', marginBottom: 16 }}>
                  Define individual starter citizens with their class, vocation, and optional traits.
                  If no citizens are defined, random citizens will be generated based on initial count.
                </p>

                <Button
                  type="dashed"
                  icon={<PlusOutlined />}
                  onClick={addStarterCitizen}
                  style={{ marginBottom: 16 }}
                >
                  Add Citizen
                </Button>

                {starterCitizens.map((citizen, index) => (
                  <Row key={index} gutter={8} style={{ marginBottom: 12 }} align="top">
                    <Col span={1}>
                      <span style={{ color: '#888', lineHeight: '32px' }}>#{index + 1}</span>
                    </Col>
                    <Col span={6}>
                      <Select
                        style={{ width: '100%' }}
                        value={citizen.classId}
                        onChange={(value) => updateStarterCitizen(index, 'classId', value)}
                        placeholder="Class"
                      >
                        {characterClasses.map(cls => (
                          <Select.Option key={cls.id} value={cls.id}>{cls.id} ({cls.name})</Select.Option>
                        ))}
                      </Select>
                    </Col>
                    <Col span={6}>
                      <Select
                        style={{ width: '100%' }}
                        value={citizen.vocationId}
                        onChange={(value) => updateStarterCitizen(index, 'vocationId', value)}
                        placeholder="Vocation"
                        showSearch
                        optionFilterProp="children"
                        filterOption={(input, option) =>
                          (option?.children as unknown as string)?.toLowerCase().includes(input.toLowerCase())
                        }
                      >
                        {workerTypes.map(wt => (
                          <Select.Option key={wt.id} value={wt.id}>{wt.id} ({wt.name})</Select.Option>
                        ))}
                      </Select>
                    </Col>
                    <Col span={9}>
                      <Select
                        mode="multiple"
                        style={{ width: '100%' }}
                        value={citizen.traitIds || []}
                        onChange={(values) => updateStarterCitizen(index, 'traitIds', values)}
                        placeholder="Traits (optional)"
                        allowClear
                        showSearch
                        optionFilterProp="children"
                        filterOption={(input, option) =>
                          (option?.children as unknown as string)?.toLowerCase().includes(input.toLowerCase())
                        }
                        maxTagCount={2}
                        maxTagPlaceholder={(omittedValues) => `+${omittedValues.length} more`}
                      >
                        {characterTraits.map(trait => (
                          <Select.Option key={trait.id} value={trait.id}>{trait.id}</Select.Option>
                        ))}
                      </Select>
                    </Col>
                    <Col span={2}>
                      <Button
                        type="link"
                        danger
                        icon={<MinusCircleOutlined />}
                        onClick={() => removeStarterCitizen(index)}
                      />
                    </Col>
                  </Row>
                ))}

                <Divider />
                <Row>
                  <Col span={24}>
                    <div style={{ color: '#888' }}>
                      <p><strong>Citizens defined:</strong> {starterCitizens.length}</p>
                      <p><strong>Initial count setting:</strong> {form.getFieldValue('initialCount') || 15}</p>
                      <p style={{ fontSize: 12 }}>
                        Note: If fewer citizens are defined than initial count, additional random citizens will be generated.
                      </p>
                    </div>
                  </Col>
                </Row>
              </>
            )}
          </TabPane>

          {useV2Mode && (
            <TabPane tab="Land Plots" key="land-plots">
              <Alert
                message="Starter Land Plots"
                description="Pre-allocate land ownership for the starting location. Land plots are defined by grid coordinates. Citizens own land based on their index."
                type="info"
                showIcon
                icon={<InfoCircleOutlined />}
                style={{ marginBottom: 16 }}
              />

              <Button
                type="dashed"
                icon={<PlusOutlined />}
                onClick={addStarterLandPlot}
                style={{ marginBottom: 16 }}
              >
                Add Land Plot
              </Button>

              <Table
                dataSource={starterLandPlots.map((plot, index) => ({ ...plot, _index: index }))}
                rowKey="_index"
                pagination={false}
                size="small"
                columns={[
                  {
                    title: '#',
                    dataIndex: '_index',
                    key: '_index',
                    width: 50,
                    render: (index: number) => <span style={{ color: '#888' }}>#{index + 1}</span>
                  },
                  {
                    title: 'Grid X',
                    dataIndex: 'gridX',
                    key: 'gridX',
                    width: 100,
                    render: (_: unknown, record: { _index: number }) => (
                      <InputNumber
                        size="small"
                        style={{ width: 80 }}
                        min={0}
                        value={starterLandPlots[record._index].gridX}
                        onChange={(v) => updateStarterLandPlot(record._index, 'gridX', v || 0)}
                      />
                    )
                  },
                  {
                    title: 'Grid Y',
                    dataIndex: 'gridY',
                    key: 'gridY',
                    width: 100,
                    render: (_: unknown, record: { _index: number }) => (
                      <InputNumber
                        size="small"
                        style={{ width: 80 }}
                        min={0}
                        value={starterLandPlots[record._index].gridY}
                        onChange={(v) => updateStarterLandPlot(record._index, 'gridY', v || 0)}
                      />
                    )
                  },
                  {
                    title: 'Owner',
                    dataIndex: 'ownerCitizenIndex',
                    key: 'ownerCitizenIndex',
                    render: (_: unknown, record: { _index: number }) => (
                      <Select
                        size="small"
                        style={{ width: 180 }}
                        value={starterLandPlots[record._index].ownerCitizenIndex}
                        onChange={(v) => updateStarterLandPlot(record._index, 'ownerCitizenIndex', v)}
                        placeholder="Town-owned"
                        allowClear
                      >
                        {starterCitizensV2.map((c, ci) => (
                          <Select.Option key={ci} value={ci}>
                            <Tag color={ROLE_COLORS[c.intendedRole]}>#{ci + 1}</Tag>
                            {c.intendedRole}
                          </Select.Option>
                        ))}
                      </Select>
                    )
                  },
                  {
                    title: 'Purchase Price',
                    dataIndex: 'purchasePrice',
                    key: 'purchasePrice',
                    width: 120,
                    render: (_: unknown, record: { _index: number }) => (
                      <InputNumber
                        size="small"
                        style={{ width: 100 }}
                        min={0}
                        value={starterLandPlots[record._index].purchasePrice}
                        onChange={(v) => updateStarterLandPlot(record._index, 'purchasePrice', v)}
                        placeholder="Auto"
                      />
                    )
                  },
                  {
                    title: '',
                    key: 'actions',
                    width: 50,
                    render: (_: unknown, record: { _index: number }) => (
                      <Button
                        type="link"
                        danger
                        icon={<MinusCircleOutlined />}
                        onClick={() => removeStarterLandPlot(record._index)}
                      />
                    )
                  }
                ]}
              />

              <Divider />
              <Row gutter={16}>
                <Col span={8}>
                  <div><strong>Total Plots:</strong> {starterLandPlots.length}</div>
                </Col>
                <Col span={8}>
                  <div>
                    <strong>Town-owned:</strong>{' '}
                    <Tag color="blue">
                      {starterLandPlots.filter(p => p.ownerCitizenIndex === undefined).length}
                    </Tag>
                  </div>
                </Col>
                <Col span={8}>
                  <div>
                    <strong>Citizen-owned:</strong>{' '}
                    <Tag color="green">
                      {starterLandPlots.filter(p => p.ownerCitizenIndex !== undefined).length}
                    </Tag>
                  </div>
                </Col>
              </Row>

              <div style={{ marginTop: 16, color: '#888' }}>
                <p>Grid coordinates correspond to the land system grid. Configure grid settings in the Land System manager.</p>
                <p>Leave purchase price blank to use automatic pricing based on terrain and location.</p>
              </div>
            </TabPane>
          )}
        </Tabs>
      </Modal>
    </div>
  );
};

export default StartingLocationManager;
