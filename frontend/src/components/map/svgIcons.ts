/**
 * RakshaNet — SVG Icon Generators
 * Adheres to Lucide style (2px stroke, round caps) from design.md Section 4.4
 */

export type RescueUnitType = 'boat' | 'truck' | '4wd' | 'ambulance' | 'helicopter';

export function getUnitTypeIconSvg(type: RescueUnitType, color: string = '#FFFFFF', size: number = 18): string {
  switch (type) {
    case 'boat':
      return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <!-- Hull -->
        <path d="M2 17l2 4h16l2-4L12 15z" />
        <!-- Mast/Cabin -->
        <path d="M12 4v11" />
        <path d="M12 5l6 6H12" />
        <!-- Lifebuoy / Water ripples -->
        <path d="M4 21c2 0 3-1 5-1s3 1 5 1 3-1 5-1" />
      </svg>`;

    case 'truck':
    case '4wd':
      return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="1" y="4" width="15" height="11" rx="2" />
        <path d="M16 8h4l3 3v4h-7V8z" />
        <!-- Wheels with rugged off-road tread -->
        <circle cx="6" cy="18" r="3" />
        <circle cx="18" cy="18" r="3" />
        <path d="M9 18h6" />
        <path d="M1 18h2" />
        <path d="M21 18h2" />
      </svg>`;

    case 'ambulance':
      return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="2" y="5" width="14" height="11" rx="2" />
        <path d="M16 8h4l2 3v5h-6V8z" />
        <!-- Cross -->
        <path d="M9 8v5" />
        <path d="M6.5 10.5h5" />
        <!-- Wheels -->
        <circle cx="6" cy="18" r="2.5" />
        <circle cx="18" cy="18" r="2.5" />
        <path d="M8.5 18h7" />
      </svg>`;

    case 'helicopter':
      return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <!-- Rotor -->
        <path d="M4 3h16" />
        <path d="M12 3v4" />
        <!-- Fuselage -->
        <path d="M7 7h8a4 4 0 0 1 4 4v2a2 2 0 0 1-2 2H7a3 3 0 0 1-3-3v-2a3 3 0 0 1 3-3z" />
        <!-- Tail & tail rotor -->
        <path d="M4 11l-3-2v4z" />
        <!-- Landing Skids -->
        <path d="M6 19h10" />
        <path d="M8 15v4" />
        <path d="M14 15v4" />
      </svg>`;

    default:
      return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M12 2L2 7l10 5 10-5-10-5z" />
        <path d="M2 17l10 5 10-5" />
        <path d="M2 12l10 5 10-5" />
      </svg>`;
  }
}

export function getWaterFloodIconSvg(color: string = '#38BDF8', size: number = 18): string {
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z" />
    <path d="M2 18c1.5 1 3.5 1 5 0s3.5-1 5 0 3.5 1 5 0 3.5-1 5 0" />
  </svg>`;
}

export function getLandslideIconSvg(color: string = '#FFA033', size: number = 18): string {
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <!-- Mountain ridge with landslide slope / cracks -->
    <path d="m8 3 4 8 5-5 5 15H2L8 3z" />
    <path d="M4.14 15.08 7.5 11" />
    <!-- Falling rocks -->
    <circle cx="16" cy="14" r="1.5" fill="${color}" />
    <circle cx="19" cy="11" r="1" fill="${color}" />
    <circle cx="13" cy="18" r="1.5" fill="${color}" />
  </svg>`;
}

export function getSosBeaconIconSvg(color: string = '#FFFFFF', size: number = 18): string {
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
  </svg>`;
}

export function getRadioMeshIconSvg(color: string = '#3CC6D0', size: number = 18): string {
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="12" cy="12" r="2" />
    <path d="M16.24 7.76a6 6 0 0 1 0 8.49m-8.48-.01a6 6 0 0 1 0-8.49m11.31-2.82a10 10 0 0 1 0 14.14m-14.14 0a10 10 0 0 1 0-14.14" />
  </svg>`;
}

export function getRadioOffIconSvg(color: string = '#A98BFF', size: number = 18): string {
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <line x1="1" y1="1" x2="23" y2="23" />
    <path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55" />
    <path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39" />
    <path d="M10.71 5.05A16 16 0 0 1 22.58 9" />
    <path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88" />
    <path d="M8.53 16.11a6 6 0 0 1-.53-.86" />
    <circle cx="12" cy="12" r="1.5" />
  </svg>`;
}

export function getSearchRadarIconSvg(color: string = '#FFC400', size: number = 18): string {
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="12" cy="12" r="10" />
    <circle cx="12" cy="12" r="6" />
    <circle cx="12" cy="12" r="2" />
    <path d="M12 2v20" />
    <path d="M2 12h20" />
    <path d="m12 12 7-7" stroke-dasharray="2 2" />
  </svg>`;
}
