import React, { useState } from 'react';
import {
  Settings,
  Shield,
  Bot,
  Database,
  Save,
  Check,
} from 'lucide-react';
import { Card } from '../../components/common/Card';
import { Button } from '../../components/common/Button';

export const SettingsPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState('General');
  const [saved, setSaved] = useState(false);

  // System Settings State
  const [allowRegistration, setAllowRegistration] = useState(true);
  const [enableMesh, setEnableMesh] = useState(true);
  const [storeLocally, setStoreLocally] = useState(true);
  const [autoSync, setAutoSync] = useState(true);

  // AI Assistant Settings State
  const [offlineAi, setOfflineAi] = useState(true);
  const [localKnowledge, setLocalKnowledge] = useState(true);

  // Data & Privacy State
  const [retentionDays, setRetentionDays] = useState(90);
  const [anonymousUsage, setAnonymousUsage] = useState(true);

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const tabs = ['General', 'Incidents', 'Users', 'Notifications', 'API & Integrations'];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1
            className="text-2xl sm:text-3xl font-black text-[#16202D] dark:text-white tracking-tight"
            style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
          >
            Settings & Management
          </h1>
          <p className="text-xs sm:text-sm text-[#566070] dark:text-[#9FADC2]">
            System configuration, offline DTN routing policies, and AI parameters
          </p>
        </div>

        <Button
          variant="primary"
          size="md"
          leftIcon={saved ? <Check size={16} /> : <Save size={16} />}
          onClick={handleSave}
        >
          {saved ? 'Saved Successfully' : 'Save Changes'}
        </Button>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
        {tabs.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
              activeTab === tab
                ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400]'
                : 'bg-white dark:bg-[#162036] border border-[#E6DCA8] dark:border-[#26344F] text-[#566070] dark:text-[#9FADC2]'
            }`}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Settings Sections matching media_1791015140209.jpg */}
      <div className="space-y-6 max-w-4xl">
        {/* System Settings */}
        <Card>
          <div className="flex items-center gap-2 mb-4 pb-2 border-b border-[#E6DCA8] dark:border-[#26344F]">
            <Shield size={18} className="text-[#8A5A00] dark:text-[#FFD21F]" />
            <h3 className="text-sm font-bold text-[#16202D] dark:text-white uppercase tracking-wider">
              System Settings
            </h3>
          </div>

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-[#16202D] dark:text-white block">
                  Allow new user registration
                </span>
                <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">
                  Permit anonymous devices to enroll in ad-hoc mesh
                </span>
              </div>
              <input
                type="checkbox"
                checked={allowRegistration}
                onChange={(e) => setAllowRegistration(e.target.checked)}
                className="w-5 h-5 accent-[#FFC400] cursor-pointer"
              />
            </div>

            <div className="flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-[#16202D] dark:text-white block">
                  Enable offline mesh network
                </span>
                <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">
                  BLE and Wi-Fi Direct store-and-forward relaying
                </span>
              </div>
              <input
                type="checkbox"
                checked={enableMesh}
                onChange={(e) => setEnableMesh(e.target.checked)}
                className="w-5 h-5 accent-[#FFC400] cursor-pointer"
              />
            </div>

            <div className="flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-[#16202D] dark:text-white block">
                  Store messages locally
                </span>
                <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">
                  Encrypt buffered packets with AES-GCM on local storage
                </span>
              </div>
              <input
                type="checkbox"
                checked={storeLocally}
                onChange={(e) => setStoreLocally(e.target.checked)}
                className="w-5 h-5 accent-[#FFC400] cursor-pointer"
              />
            </div>

            <div className="flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-[#16202D] dark:text-white block">
                  Auto-sync when online
                </span>
                <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">
                  Flush opportunistically to satellite / gateway uplink
                </span>
              </div>
              <input
                type="checkbox"
                checked={autoSync}
                onChange={(e) => setAutoSync(e.target.checked)}
                className="w-5 h-5 accent-[#FFC400] cursor-pointer"
              />
            </div>
          </div>
        </Card>

        {/* AI Assistant Settings */}
        <Card>
          <div className="flex items-center gap-2 mb-4 pb-2 border-b border-[#E6DCA8] dark:border-[#26344F]">
            <Bot size={18} className="text-[#0E8A94] dark:text-[#3CC6D0]" />
            <h3 className="text-sm font-bold text-[#16202D] dark:text-white uppercase tracking-wider">
              AI Assistant Settings
            </h3>
          </div>

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-[#16202D] dark:text-white block">
                  Enable offline AI guidance
                </span>
                <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">
                  On-device distilled model for triage recommendations
                </span>
              </div>
              <input
                type="checkbox"
                checked={offlineAi}
                onChange={(e) => setOfflineAi(e.target.checked)}
                className="w-5 h-5 accent-[#FFC400] cursor-pointer"
              />
            </div>

            <div className="flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-[#16202D] dark:text-white block">
                  Use local knowledge base
                </span>
                <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">
                  Embed NDMA disaster SOPs and offline first aid protocols
                </span>
              </div>
              <input
                type="checkbox"
                checked={localKnowledge}
                onChange={(e) => setLocalKnowledge(e.target.checked)}
                className="w-5 h-5 accent-[#FFC400] cursor-pointer"
              />
            </div>
          </div>
        </Card>

        {/* Data & Privacy */}
        <Card>
          <div className="flex items-center gap-2 mb-4 pb-2 border-b border-[#E6DCA8] dark:border-[#26344F]">
            <Database size={18} className="text-[#D92D20] dark:text-[#FF5A4E]" />
            <h3 className="text-sm font-bold text-[#16202D] dark:text-white uppercase tracking-wider">
              Data & Privacy
            </h3>
          </div>

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-[#16202D] dark:text-white block">
                  Data retention (days)
                </span>
                <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">
                  Auto-purge resolved telemetry and expired packets
                </span>
              </div>
              <input
                type="number"
                value={retentionDays}
                onChange={(e) => setRetentionDays(Number(e.target.value))}
                className="w-20 h-9 px-2 text-center rounded-xl bg-white dark:bg-[#0E1627] border border-[#E6DCA8] dark:border-[#26344F] text-xs font-mono font-bold text-[#16202D] dark:text-white"
              />
            </div>

            <div className="flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-[#16202D] dark:text-white block">
                  Allow anonymous usage
                </span>
                <span className="text-[11px] text-[#566070] dark:text-[#9FADC2]">
                  Strip PII and use pseudo-identifiers (e.g. SR-8F42)
                </span>
              </div>
              <input
                type="checkbox"
                checked={anonymousUsage}
                onChange={(e) => setAnonymousUsage(e.target.checked)}
                className="w-5 h-5 accent-[#FFC400] cursor-pointer"
              />
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default SettingsPage;
