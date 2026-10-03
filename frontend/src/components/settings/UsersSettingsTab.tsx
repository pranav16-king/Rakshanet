// src/components/settings/UsersSettingsTab.tsx
import React, { useState } from 'react';
import { SettingsToggleRow } from './SettingsToggleRow';
import { UserCheck, Key, Shield } from 'lucide-react';

export const UsersSettingsTab: React.FC = () => {
  const [require2fa, setRequire2fa] = useState(false);
  const [sessionTimeoutHours, setSessionTimeoutHours] = useState(24);
  const [allowGuestBeacon, setAllowGuestBeacon] = useState(true);

  return (
    <div className="p-6 rounded-xl border border-slate-700/80 bg-[#162036] shadow-sm space-y-4">
      <div>
        <h3 className="text-base font-bold text-white">Identity &amp; Access Controls</h3>
        <p className="text-xs text-slate-400">
          Manage dispatcher authentication, authorization roles, and mesh node pseudonym policies.
        </p>
      </div>

      <div className="divide-y divide-slate-800">
        <SettingsToggleRow
          label="Require Multi-Factor Authentication (MFA)"
          description="Mandatory for Field Commanders and Command Center Administrators."
          checked={require2fa}
          onChange={setRequire2fa}
          icon={<Key className="w-5 h-5 text-amber-400" />}
        />

        <SettingsToggleRow
          label="Permit Anonymous Survivor SOS Pings"
          description="Allow handsets to broadcast distress packets without prior account registration."
          checked={allowGuestBeacon}
          onChange={setAllowGuestBeacon}
          icon={<Shield className="w-5 h-5 text-emerald-400" />}
        />
      </div>

      <div className="flex items-center justify-between py-3 border-t border-slate-800">
        <div>
          <div className="text-sm font-medium text-slate-100">Command Center Session Expiry</div>
          <div className="text-xs text-slate-400">Duration in hours before dispatcher is prompted to re-authenticate.</div>
        </div>
        <div className="flex items-center gap-2">
          <input
            type="number"
            value={sessionTimeoutHours}
            onChange={(e) => setSessionTimeoutHours(Number(e.target.value))}
            className="w-20 bg-[#0E1627] border border-slate-700 rounded-lg px-3 py-1.5 text-sm text-center font-mono text-white focus:outline-none focus:border-amber-400"
          />
          <span className="text-xs text-slate-400">hours</span>
        </div>
      </div>
    </div>
  );
};
