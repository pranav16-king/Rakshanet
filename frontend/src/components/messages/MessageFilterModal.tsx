import React, { useState } from 'react';
import { X, Filter, Check } from 'lucide-react';
import type { DeliveryStatus } from '../../types/messages';

interface FilterCriteria {
  deliveryStatus?: DeliveryStatus | 'all';
  location?: string;
  hasIncident?: boolean;
}

interface MessageFilterModalProps {
  isOpen: boolean;
  onClose: () => void;
  onApply: (criteria: FilterCriteria) => void;
  currentCriteria: FilterCriteria;
}

export const MessageFilterModal: React.FC<MessageFilterModalProps> = ({
  isOpen,
  onClose,
  onApply,
  currentCriteria,
}) => {
  const [status, setStatus] = useState<DeliveryStatus | 'all'>(
    currentCriteria.deliveryStatus || 'all'
  );
  const [location, setLocation] = useState(currentCriteria.location || 'all');
  const [onlyIncidents, setOnlyIncidents] = useState(
    currentCriteria.hasIncident || false
  );

  if (!isOpen) return null;

  const handleApply = () => {
    onApply({
      deliveryStatus: status,
      location: location === 'all' ? undefined : location,
      hasIncident: onlyIncidents,
    });
    onClose();
  };

  const handleReset = () => {
    setStatus('all');
    setLocation('all');
    setOnlyIncidents(false);
    onApply({
      deliveryStatus: 'all',
      location: undefined,
      hasIncident: false,
    });
    onClose();
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="filter-dialog-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs"
    >
      <div className="bg-white dark:bg-slate-900 rounded-2xl max-w-md w-full border border-slate-200 dark:border-slate-800 shadow-xl overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 dark:border-slate-800">
          <div className="flex items-center gap-2">
            <Filter className="w-5 h-5 text-[#8A5A00] dark:text-[#FFC400]" />
            <h3 id="filter-dialog-title" className="text-base font-bold text-slate-900 dark:text-slate-100">
              Filter Communications
            </h3>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 p-1.5 rounded-lg"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6 space-y-5">
          {/* Delivery Status */}
          <div>
            <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-2">
              Delivery Network Status
            </label>
            <div className="grid grid-cols-2 gap-2">
              {[
                { id: 'all', label: 'All Statuses' },
                { id: 'delivered', label: 'Delivered (Double Green)' },
                { id: 'relayed', label: 'Mesh Relayed (2 Ticks)' },
                { id: 'queued', label: 'Queued (1 Tick)' },
              ].map((item) => (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => setStatus(item.id as DeliveryStatus | 'all')}
                  className={`px-3 py-2 text-xs font-medium rounded-lg border text-left flex items-center justify-between transition-colors ${
                    status === item.id
                      ? 'bg-[#FFC400]/15 border-[#FFC400] text-slate-900 dark:text-slate-100 font-semibold'
                      : 'border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800'
                  }`}
                >
                  <span>{item.label}</span>
                  {status === item.id && <Check className="w-3.5 h-3.5 text-[#8A5A00] dark:text-[#FFC400]" />}
                </button>
              ))}
            </div>
          </div>

          {/* Location */}
          <div>
            <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-2">
              Region / Location
            </label>
            <select
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#FFC400]"
            >
              <option value="all">All Sectors</option>
              <option value="Sector 4B Riverside Colony">Sector 4B Riverside Colony (Ward 14)</option>
              <option value="South Market Commercial Plaza">South Market Commercial Plaza</option>
              <option value="NH-48 Mountain Pass km 74">NH-48 Mountain Pass km 74</option>
              <option value="Kovalam Coast Sector 1">Kovalam Coast Sector 1</option>
              <option value="Industrial Park Gate 3">Industrial Park Gate 3</option>
              <option value="Guindy Metro Relief Shelter">Guindy Metro Relief Shelter</option>
            </select>
          </div>

          {/* Only Linked to Active Incident */}
          <div className="pt-2">
            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={onlyIncidents}
                onChange={(e) => setOnlyIncidents(e.target.checked)}
                className="w-4 h-4 rounded text-[#FFC400] focus:ring-[#FFC400] border-slate-300"
              />
              <span className="text-sm text-slate-700 dark:text-slate-300 font-medium">
                Only show active SOS & incident linked messages
              </span>
            </label>
          </div>
        </div>

        <div className="flex items-center justify-between px-6 py-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-100 dark:border-slate-800">
          <button
            type="button"
            onClick={handleReset}
            className="text-xs font-semibold text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
          >
            Reset All
          </button>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-semibold text-slate-700 dark:text-slate-300 hover:bg-slate-200/50 dark:hover:bg-slate-700 rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={handleApply}
              className="px-4 py-2 text-xs font-bold bg-[#FFC400] hover:bg-[#E0AA00] text-slate-950 rounded-lg shadow-xs transition-colors"
            >
              Apply Filters
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MessageFilterModal;
