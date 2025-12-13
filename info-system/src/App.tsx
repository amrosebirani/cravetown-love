import { useState, useEffect } from 'react';
import { Layout, Menu, Spin, ConfigProvider, theme, Switch, Space } from 'antd';
import { DatabaseOutlined, AppstoreOutlined, TeamOutlined, HomeOutlined, TagsOutlined,
         BulbOutlined, UserOutlined, SmileOutlined, GiftOutlined, ThunderboltOutlined, SwapOutlined, BranchesOutlined, FireOutlined, NodeIndexOutlined, ClockCircleOutlined, LinkOutlined, CalculatorOutlined, EnvironmentOutlined, GlobalOutlined, MoonOutlined, SunOutlined } from '@ant-design/icons';
import RecipeManager from './components/RecipeManager';
import CommodityManager from './components/CommodityManager';
import CommodityCategoryManager from './components/CommodityCategoryManager';
import WorkerTypeManager from './components/WorkerTypeManager';
import BuildingTypeManager from './components/BuildingTypeManager';
import WorkCategoryManager from './components/WorkCategoryManager';
import DimensionManager from './components/DimensionManager';
import CharacterClassManager from './components/CharacterClassManager';
import TraitManager from './components/TraitManager';
import FulfillmentVectorManager from './components/FulfillmentVectorManager';
import EnablementRulesManager from './components/EnablementRulesManager';
import SubstitutionCalculator from './components/SubstitutionCalculator';
import CommodityFatigueManager from './components/CommodityFatigueManager';
import SubstitutionRulesManager from './components/SubstitutionRulesManager';
import VersionManager from './components/VersionManager';
import TimeSlotManager from './components/TimeSlotManager';
import CravingSlotManager from './components/CravingSlotManager';
import UnitsManager from './components/UnitsManager';
import StartingLocationManager from './components/StartingLocationManager';
import ClassThresholdsManager from './components/ClassThresholdsManager';
import LandConfigManager from './components/LandConfigManager';
import HousingConfigManager from './components/HousingConfigManager';
import { initializeVersionSystem } from './api';
import './App.css';

const { Header, Content, Sider } = Layout;

type TabKey = 'versions' | 'recipes' | 'commodities' | 'commodity-categories' | 'workers' | 'buildings' | 'work-categories' |
              'dimensions' | 'character-classes' | 'traits' | 'fulfillment-vectors' | 'enablement-rules' |
              'substitution-calculator' | 'commodity-fatigue' | 'substitution-rules' |
              'time-slots' | 'craving-slots' | 'units' | 'starting-locations' |
              'class-thresholds' | 'land-config' | 'housing-config';

function App() {
  const [selectedTab, setSelectedTab] = useState<TabKey>('recipes');
  const [loading, setLoading] = useState(true);
  const [activeVersion, setActiveVersion] = useState<string>('base');
  const [isDarkMode, setIsDarkMode] = useState(() => {
    // Check localStorage for saved preference, default to dark
    const saved = localStorage.getItem('theme');
    return saved ? saved === 'dark' : true;
  });

  useEffect(() => {
    // Save theme preference
    localStorage.setItem('theme', isDarkMode ? 'dark' : 'light');
    // Update body class for CSS transitions
    document.body.classList.toggle('dark-mode', isDarkMode);
  }, [isDarkMode]);

  useEffect(() => {
    // Initialize version system and load active version
    const init = async () => {
      try {
        const versionId = await initializeVersionSystem();
        setActiveVersion(versionId);
      } catch (error) {
        console.error('Failed to initialize version system:', error);
      } finally {
        setLoading(false);
      }
    };

    init();
  }, []);

  const menuItems = [
    {
      type: 'group' as const,
      label: 'System',
      children: [
        {
          key: 'versions',
          icon: <BranchesOutlined />,
          label: 'Version Manager',
        },
        {
          key: 'starting-locations',
          icon: <EnvironmentOutlined />,
          label: 'Starting Locations',
        },
      ]
    },
    {
      type: 'group' as const,
      label: 'Production System',
      children: [
        {
          key: 'buildings',
          icon: <HomeOutlined />,
          label: 'Building Types',
        },
        {
          key: 'recipes',
          icon: <DatabaseOutlined />,
          label: 'Building Recipes',
        },
        {
          key: 'commodities',
          icon: <AppstoreOutlined />,
          label: 'Commodities',
        },
        {
          key: 'commodity-categories',
          icon: <TagsOutlined />,
          label: 'Commodity Categories',
        },
        {
          key: 'workers',
          icon: <TeamOutlined />,
          label: 'Worker Types',
        },
        {
          key: 'work-categories',
          icon: <TagsOutlined />,
          label: 'Work Categories',
        },
      ]
    },
    {
      type: 'group' as const,
      label: 'Time System',
      children: [
        {
          key: 'time-slots',
          icon: <ClockCircleOutlined />,
          label: 'Time Slots',
        },
        {
          key: 'units',
          icon: <CalculatorOutlined />,
          label: 'Units & Baselines',
        },
      ]
    },
    {
      type: 'group' as const,
      label: 'Economy & Housing',
      children: [
        {
          key: 'class-thresholds',
          icon: <UserOutlined />,
          label: 'Class Thresholds',
        },
        {
          key: 'land-config',
          icon: <GlobalOutlined />,
          label: 'Land System',
        },
        {
          key: 'housing-config',
          icon: <HomeOutlined />,
          label: 'Housing Config',
        },
      ]
    },
    {
      type: 'group' as const,
      label: 'Craving System',
      children: [
        {
          key: 'dimensions',
          icon: <BulbOutlined />,
          label: 'Craving Dimensions',
        },
        {
          key: 'craving-slots',
          icon: <LinkOutlined />,
          label: 'Craving-Slot Mapping',
        },
        {
          key: 'character-classes',
          icon: <UserOutlined />,
          label: 'Character Classes',
        },
        {
          key: 'traits',
          icon: <SmileOutlined />,
          label: 'Character Traits',
        },
        {
          key: 'fulfillment-vectors',
          icon: <GiftOutlined />,
          label: 'Fulfillment Vectors',
        },
        {
          key: 'enablement-rules',
          icon: <ThunderboltOutlined />,
          label: 'Enablement Rules',
        },
        {
          key: 'commodity-fatigue',
          icon: <FireOutlined />,
          label: 'Commodity Fatigue',
        },
        {
          key: 'substitution-rules',
          icon: <NodeIndexOutlined />,
          label: 'Substitution Rules',
        },
        {
          key: 'substitution-calculator',
          icon: <SwapOutlined />,
          label: 'Substitution Calculator',
        },
      ]
    },
  ];

  return (
    <ConfigProvider
      theme={{
        algorithm: isDarkMode ? theme.darkAlgorithm : theme.defaultAlgorithm,
        token: {
          colorPrimary: '#1890ff',
          borderRadius: 6,
        },
        components: {
          Layout: {
            headerBg: isDarkMode ? '#141414' : '#001529',
            siderBg: isDarkMode ? '#1f1f1f' : '#fff',
            bodyBg: isDarkMode ? '#0a0a0a' : '#f0f2f5',
          },
          Menu: {
            darkItemBg: '#1f1f1f',
            darkSubMenuItemBg: '#1f1f1f',
          },
        },
      }}
    >
      <Layout style={{ minHeight: '100vh' }}>
        <Header style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0 24px',
          borderBottom: isDarkMode ? '1px solid #303030' : 'none',
        }}>
          <div style={{
            color: 'white',
            fontSize: '20px',
            fontWeight: 'bold',
          }}>
            CraveTown Information System
          </div>
          <Space>
            <SunOutlined style={{ color: isDarkMode ? '#666' : '#ffd700', fontSize: '16px' }} />
            <Switch
              checked={isDarkMode}
              onChange={setIsDarkMode}
              checkedChildren={<MoonOutlined />}
              unCheckedChildren={<SunOutlined />}
            />
            <MoonOutlined style={{ color: isDarkMode ? '#1890ff' : '#666', fontSize: '16px' }} />
          </Space>
        </Header>

        <Layout>
          <Sider
            width={200}
            style={{
              borderRight: isDarkMode ? '1px solid #303030' : '1px solid #f0f0f0',
            }}
            theme={isDarkMode ? 'dark' : 'light'}
          >
            <Menu
              mode="inline"
              selectedKeys={[selectedTab]}
              onClick={({ key }) => setSelectedTab(key as TabKey)}
              style={{ height: '100%', borderRight: 0 }}
              theme={isDarkMode ? 'dark' : 'light'}
              items={menuItems}
            />
          </Sider>

          <Layout style={{ padding: '24px' }}>
            <Content
              style={{
                padding: 24,
                margin: 0,
                minHeight: 280,
                background: isDarkMode ? '#141414' : '#fff',
                borderRadius: '8px',
                border: isDarkMode ? '1px solid #303030' : 'none',
              }}
            >
              {loading ? (
                <div style={{
                  display: 'flex',
                  justifyContent: 'center',
                  alignItems: 'center',
                  height: '400px'
                }}>
                  <Spin size="large" tip="Loading..." />
                </div>
              ) : (
                <>
                  {selectedTab === 'versions' && <VersionManager />}
                  {selectedTab === 'starting-locations' && <StartingLocationManager />}
                  {selectedTab === 'buildings' && <BuildingTypeManager />}
                  {selectedTab === 'recipes' && <RecipeManager />}
                  {selectedTab === 'commodities' && <CommodityManager />}
                  {selectedTab === 'commodity-categories' && <CommodityCategoryManager />}
                  {selectedTab === 'workers' && <WorkerTypeManager />}
                  {selectedTab === 'work-categories' && <WorkCategoryManager />}
                  {selectedTab === 'dimensions' && <DimensionManager />}
                  {selectedTab === 'character-classes' && <CharacterClassManager />}
                  {selectedTab === 'traits' && <TraitManager />}
                  {selectedTab === 'fulfillment-vectors' && <FulfillmentVectorManager />}
                  {selectedTab === 'enablement-rules' && <EnablementRulesManager />}
                  {selectedTab === 'commodity-fatigue' && <CommodityFatigueManager />}
                  {selectedTab === 'substitution-rules' && <SubstitutionRulesManager />}
                  {selectedTab === 'substitution-calculator' && <SubstitutionCalculator />}
                  {selectedTab === 'time-slots' && <TimeSlotManager />}
                  {selectedTab === 'craving-slots' && <CravingSlotManager />}
                  {selectedTab === 'units' && <UnitsManager />}
                  {selectedTab === 'class-thresholds' && <ClassThresholdsManager />}
                  {selectedTab === 'land-config' && <LandConfigManager />}
                  {selectedTab === 'housing-config' && <HousingConfigManager />}
                </>
              )}
            </Content>
          </Layout>
        </Layout>
      </Layout>
    </ConfigProvider>
  );
}

export default App;
