import React from 'react';
import type { ConnectionLog } from '../../types/devices';
import { Radio, ArrowRight, ShieldCheck, AlertCircle } from 'lucide-react';

interface ConnectionLogsTableProps {
  logs: ConnectionLog[];
}

export const ConnectionLogsTable: React.FC<ConnectionLogsTableProps> = ({ logs }) => {
  const getStatusBadge = (status: ConnectionLog['status']) => {
    switch (status) {
      case 'Delivered':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-semibold bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300">
            <ShieldCheck className="w-3 h-3" />
            Delivered
          </span>
        );
      case 'Relayed':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-semibold bg-sky-50 text-sky-700 dark:bg-sky-950/40 dark:text-sky-300">
            <Radio className="w-3 h-3" />
            Relayed
          </span>
        );
      case 'Dropped':
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-semibold bg-red-50 text-red-700 dark:bg-red-950/40 dark:text-red-300">
            <AlertCircle className="w-3 h-3" />
            Dropped
          </span>
        );
    }
  };

  return (
    <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 shadow-xs">
      <table className="w-full text-left text-sm text-slate-700 dark:text-slate-200">
        <thead className="bg-slate-50 dark:bg-slate-800/60 border-b border-slate-200 dark:border-slate-800 text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
          <tr>
            <th scope="col" className="px-5 py-3.5">Time</th>
            <th scope="col" className="px-5 py-3.5">Device ID</th>
            <th scope="col" className="px-5 py-3.5">User</th>
            <th scope="col" className="px-5 py-3.5">Event Details</th>
            <th scope="col" className="px-5 py-3.5">Protocol</th>
            <th scope="col" className="px-5 py-3.5">Hops</th>
            <th scope="col" className="px-5 py-3.5">RSSI</th>
            <th scope="col" className="px-5 py-3.5 text-right">Status</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100 dark:divide-slate-800/80 font-normal">
          {logs.map((log) => (
            <tr
              key={log.id}
              className="hover:bg-slate-50/80 dark:hover:bg-slate-800/40 transition-colors"
            >
              <td className="px-5 py-3 whitespace-nowrap font-mono text-xs text-slate-500">
                {log.timestamp}
              </td>
              <td className="px-5 py-3 whitespace-nowrap font-mono text-xs font-bold text-slate-900 dark:text-slate-100">
                {log.deviceId}
              </td>
              <td className="px-5 py-3 whitespace-nowrap text-xs font-medium text-slate-800 dark:text-slate-200">
                {log.userName}
              </td>
              <td className="px-5 py-3 text-xs text-slate-600 dark:text-slate-300">
                {log.event}
              </td>
              <td className="px-5 py-3 whitespace-nowrap font-mono text-xs text-slate-500">
                {log.protocol}
              </td>
              <td className="px-5 py-3 whitespace-nowrap text-xs text-slate-600 dark:text-slate-300">
                {log.hopCount}
              </td>
              <td className="px-5 py-3 whitespace-nowrap font-mono text-xs text-slate-500">
                {log.rssiDbm} dBm
              </td>
              <td className="px-5 py-3 whitespace-nowrap text-right">
                {getStatusBadge(log.status)}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default ConnectionLogsTable;
