// src/pages/settings/SettingsPage.tsx
import React, { useState, useEffect, useCallback } from 'react';
import {
  Sliders,
  Layers,
  Users,
  Bell,
  Globe,
  Save,
  Check,
  RotateCcw,
  AlertCircle,
  Loader2,
  CheckCircle2,
  ShieldCheck,
} from 'lucide-react';
import { Button } from '../../components/common/Button';
import { settingsApi } from '../../api/settings';
import type { SystemSettings } from '../../types';
import { GeneralSettingsTab } from '../../components/settings/GeneralSettingsTab';
import { IncidentsSettingsTab } from '../../components/settings/IncidentsSettingsTab';
import { UsersSettingsTab } from '../../components/settings/UsersSettingsTab';
import { NotificationsSettingsTab } from '../../components/settings/NotificationsSettingsTab';
import { ApiIntegrationsTab } from '../../components/settings/ApiIntegrationsTab';

export const SettingsPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<string>('General');
  const [settings, setSettings] = useState<SystemSettings | null>(null);
  const [savedSettings, setSavedSettings] = useState<SystemSettings | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [saving, setSaving] = useState<boolean>(false);
  const [saveSuccess, setSaveSuccess] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isDirty, setIsDirty] = useState<boolean>(false);

  // Fetch initial settings from backend API
  const fetchSettings = useCallback(async () => {
    try {
      setLoading(true);
      setErrorMessage(null);
      const data = await settingsApi.getSettings();
      setSettings(data);
      setSavedSettings(JSON.parse(JSON.stringify(data)));
      setIsDirty(false);
    } catch (err) {
      console.error('Failed to load system settings from backend:', err);
      setErrorMessage('Could not connect to backend gateway. Showing locally cached configuration.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSettings();
  }, [fetchSettings]);

  // Handle settings mutation
  const handleSettingsChange = (updatedPartial: Partial<SystemSettings>) => {
    if (!settings) return;
    const next = { ...settings, ...updatedPartial };
    setSettings(next);
    setIsDirty(JSON.stringify(next) !== JSON.stringify(savedSettings));
  };

  // Discard local changes and revert to last saved state
  const handleDiscard = () => {
    if (savedSettings) {
      setSettings(JSON.parse(JSON.stringify(savedSettings)));
      setIsDirty(false);
    }
  };

  // Save changes to backend via POST /api/v1/settings
  const handleSave = async () => {
    if (!settings) return;
    try {
      setSaving(true);
      setErrorMessage(null);
      const updated = await settingsApi.saveSettings(settings);
      setSettings(updated);
      setSavedSettings(JSON.parse(JSON.stringify(updated)));
      setIsDirty(false);
      setSaveSuccess(true);
      setTimeout(() => {
        setSaveSuccess(false);
      }, 3500);
    } catch (err: any) {
      console.error('Failed to save settings:', err);
      setErrorMessage(err?.message || 'Failed to persist settings to gateway storage.');
    } finally {
      setSaving(false);
    }
  };

  const tabs = [
    { id: 'General', label: 'General', icon: Sliders },
    { id: 'Incidents', label: 'Incidents', icon: Layers },
    { id: 'Users', label: 'Users', icon: Users },
    { id: 'Notifications', label: 'Notifications', icon: Bell },
    { id: 'API & Integrations', label: 'API & Integrations', icon: Globe },
  ];

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[450px] space-y-4">
        <Loader2 className="w-8 h-8 text-[#FFC400] dark:text-[#FFD21F] animate-spin" />
        <p className="text-sm font-semibold text-slate-600 dark:text-slate-300">
          Loading RakshaNet gateway configuration...
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-6xl mx-auto pb-12">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-1 border-b border-slate-200/80 dark:border-[#26344F]">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <h1
              className="text-2xl sm:text-3xl font-black text-[#0F172A] dark:text-white tracking-tight"
              style={{ fontFamily: '"Barlow Semi Condensed", sans-serif' }}
            >
              Settings &amp; Management
            </h1>
            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-mono font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
              <ShieldCheck className="w-3 h-3" />
              LIVE GATEWAY
            </span>
          </div>
          <p className="text-xs sm:text-sm text-[#64748B] dark:text-[#9FADC2]">
            System configuration, offline DTN routing policies, DBSCAN parameters, and interoperability endpoints.
          </p>
        </div>

        {/* Global Save / Discard Action Bar */}
        <div className="flex items-center gap-2.5 shrink-0">
          {isDirty && (
            <button
              type="button"
              onClick={handleDiscard}
              disabled={saving}
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-xs font-bold text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-700 transition cursor-pointer"
            >
              <RotateCcw className="w-3.5 h-3.5 text-slate-500" />
              Discard
            </button>
          )}

          <Button
            variant="primary"
            size="md"
            disabled={saving || (!isDirty && !saveSuccess)}
            leftIcon={
              saving ? (
                <Loader2 size={16} className="animate-spin" />
              ) : saveSuccess ? (
                <Check size={16} className="text-emerald-900" />
              ) : (
                <Save size={16} />
              )
            }
            onClick={handleSave}
          >
            {saving
              ? 'Saving...'
              : saveSuccess
              ? 'Saved to Gateway'
              : isDirty
              ? 'Save Changes'
              : 'Up to Date'}
          </Button>
        </div>
      </div>

      {/* Success Notification Banner */}
      {saveSuccess && (
        <div className="p-3.5 rounded-xl bg-emerald-500/15 border border-emerald-500/30 text-emerald-700 dark:text-emerald-300 flex items-center justify-between text-xs font-semibold animate-in fade-in slide-in-from-top-2">
          <div className="flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-emerald-500" />
            <span>Settings successfully committed to primary SQLite database and queued for cloud mirror.</span>
          </div>
          <span className="text-[10px] font-mono uppercase bg-emerald-500/20 px-2 py-0.5 rounded">Committed</span>
        </div>
      )}

      {/* Error Alert Banner */}
      {errorMessage && (
        <div className="p-3.5 rounded-xl bg-red-500/15 border border-red-500/30 text-red-700 dark:text-red-300 flex items-center justify-between text-xs font-semibold">
          <div className="flex items-center gap-2">
            <AlertCircle className="w-4 h-4 text-red-500" />
            <span>{errorMessage}</span>
          </div>
          <button
            onClick={fetchSettings}
            className="text-[11px] underline hover:no-underline font-bold"
          >
            Retry Connection
          </button>
        </div>
      )}

      {/* Navigation Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer whitespace-nowrap ${
                isActive
                  ? 'bg-[#FFC400] dark:bg-[#FFD21F] text-[#1A1400] shadow-sm'
                  : 'bg-white dark:bg-[#162036] border border-slate-200 dark:border-[#26344F] text-slate-600 dark:text-[#9FADC2] hover:border-slate-300 dark:hover:border-slate-600 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              <Icon className="w-4 h-4" />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* Dynamic Tab Content with Real Data */}
      <div className="pt-1">
        {activeTab === 'General' && settings && (
          <GeneralSettingsTab settings={settings} onChange={handleSettingsChange} />
        )}

        {activeTab === 'Incidents' && settings && (
          <IncidentsSettingsTab settings={settings} onChange={handleSettingsChange} />
        )}

        {activeTab === 'Users' && settings && (
          <UsersSettingsTab settings={settings} onChange={handleSettingsChange} />
        )}

        {activeTab === 'Notifications' && settings && (
          <NotificationsSettingsTab settings={settings} onChange={handleSettingsChange} />
        )}

        {activeTab === 'API & Integrations' && (
          <ApiIntegrationsTab />
        )}
      </div>
    </div>
  );
};

export default SettingsPage;
