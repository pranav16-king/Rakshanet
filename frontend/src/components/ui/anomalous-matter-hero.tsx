import React, { useRef, useEffect, Suspense } from "react";
import * as THREE from "three";
import { Link } from "react-router-dom";
import { Radio, MapPin, Cpu, ShieldAlert, ArrowRight, Activity, Wifi } from "lucide-react";

interface GenerativeArtSceneProps {
  colorHex?: string;
  wireframe?: boolean;
}

export function GenerativeArtScene({
  colorHex = "#0E8A94",
  wireframe = true,
}: GenerativeArtSceneProps) {
  const mountRef = useRef<HTMLDivElement>(null);
  const lightRef = useRef<THREE.PointLight | null>(null);

  useEffect(() => {
    const currentMount = mountRef.current;
    if (!currentMount) return;

    const width = currentMount.clientWidth || window.innerWidth;
    const height = currentMount.clientHeight || window.innerHeight;

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 1000);
    camera.position.z = 2.8;

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    currentMount.appendChild(renderer.domElement);

    const geometry = new THREE.IcosahedronGeometry(1.3, 64);
    const material = new THREE.ShaderMaterial({
      uniforms: {
        time: { value: 0 },
        pointLightPos: { value: new THREE.Vector3(0, 0, 5) },
        color: { value: new THREE.Color(colorHex) },
      },
      vertexShader: `
        uniform float time;
        varying vec3 vNormal;
        varying vec3 vPosition;
        
        // Classic Perlin Noise implementation
        vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        vec4 permute(vec4 x) { return mod289(((x*34.0)+1.0)*x); }
        vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }
        
        float snoise(vec3 v) {
            const vec2 C = vec2(1.0/6.0, 1.0/3.0);
            const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
            vec3 i = floor(v + dot(v, C.yyy));
            vec3 x0 = v - i + dot(i, C.xxx);
            vec3 g = step(x0.yzx, x0.xyz);
            vec3 l = 1.0 - g;
            vec3 i1 = min(g.xyz, l.zxy);
            vec3 i2 = max(g.xyz, l.zxy);
            vec3 x1 = x0 - i1 + C.xxx;
            vec3 x2 = x0 - i2 + C.yyy;
            vec3 x3 = x0 - D.yyy;
            i = mod289(i);
            vec4 p = permute(permute(permute(
                        i.z + vec4(0.0, i1.z, i2.z, 1.0))
                    + i.y + vec4(0.0, i1.y, i2.y, 1.0))
                    + i.x + vec4(0.0, i1.x, i2.x, 1.0));
            float n_ = 0.142857142857;
            vec3 ns = n_ * D.wyz - D.xzx;
            vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
            vec4 x_ = floor(j * ns.z);
            vec4 y_ = floor(j - 7.0 * x_);
            vec4 x = x_ * ns.x + ns.yyyy;
            vec4 y = y_ * ns.x + ns.yyyy;
            vec4 h = 1.0 - abs(x) - abs(y);
            vec4 b0 = vec4(x.xy, y.xy);
            vec4 b1 = vec4(x.zw, y.zw);
            vec4 s0 = floor(b0) * 2.0 + 1.0;
            vec4 s1 = floor(b1) * 2.0 + 1.0;
            vec4 sh = -step(h, vec4(0.0));
            vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
            vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
            vec3 p0 = vec3(a0.xy, h.x);
            vec3 p1 = vec3(a0.zw, h.y);
            vec3 p2 = vec3(a1.xy, h.z);
            vec3 p3 = vec3(a1.zw, h.w);
            vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
            p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
            vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
            m = m * m;
            return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
        }

        void main() {
            vNormal = normal;
            vPosition = position;
            float displacement = snoise(position * 1.8 + time * 0.4) * 0.22;
            vec3 newPosition = position + normal * displacement;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(newPosition, 1.0);
        }
      `,
      fragmentShader: `
        uniform vec3 color;
        uniform vec3 pointLightPos;
        varying vec3 vNormal;
        varying vec3 vPosition;
        
        void main() {
            vec3 normal = normalize(vNormal);
            vec3 lightDir = normalize(pointLightPos - vPosition);
            float diffuse = max(dot(normal, lightDir), 0.0);
            
            // Fresnel edge glow for wireless beacon mesh look
            float fresnel = 1.0 - dot(normal, vec3(0.0, 0.0, 1.0));
            fresnel = pow(fresnel, 2.2);
            
            vec3 finalColor = color * (diffuse * 0.7 + 0.3) + vec3(1.0, 0.8, 0.2) * fresnel * 0.8;
            gl_FragColor = vec4(finalColor, 0.85);
        }
      `,
      wireframe: wireframe,
      transparent: true,
    });

    const mesh = new THREE.Mesh(geometry, material);
    scene.add(mesh);

    // Inner core glowing sphere
    const innerGeo = new THREE.IcosahedronGeometry(0.8, 16);
    const innerMat = new THREE.MeshBasicMaterial({
      color: new THREE.Color("#FFC400"),
      wireframe: true,
      transparent: true,
      opacity: 0.35,
    });
    const innerMesh = new THREE.Mesh(innerGeo, innerMat);
    scene.add(innerMesh);

    const pointLight = new THREE.PointLight(0xffffff, 1.5, 100);
    pointLight.position.set(0, 0, 5);
    lightRef.current = pointLight;
    scene.add(pointLight);

    let frameId: number;
    const animate = (t: number) => {
      material.uniforms.time.value = t * 0.0004;
      mesh.rotation.y += 0.0008;
      mesh.rotation.x += 0.0003;
      innerMesh.rotation.y -= 0.0005;
      renderer.render(scene, camera);
      frameId = requestAnimationFrame(animate);
    };
    animate(0);

    const handleResize = () => {
      if (!currentMount) return;
      const w = currentMount.clientWidth;
      const h = currentMount.clientHeight;
      camera.aspect = w / h;
      camera.updateProjectionMatrix();
      renderer.setSize(w, h);
    };

    const handleMouseMove = (e: MouseEvent) => {
      const rect = currentMount.getBoundingClientRect();
      const x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
      const y = -((e.clientY - rect.top) / rect.height) * 2 + 1;
      const vec = new THREE.Vector3(x, y, 0.5).unproject(camera);
      const dir = vec.sub(camera.position).normalize();
      const dist = -camera.position.z / dir.z;
      const pos = camera.position.clone().add(dir.multiplyScalar(dist));
      if (lightRef.current) {
        lightRef.current.position.copy(pos);
      }
      material.uniforms.pointLightPos.value = pos;
    };

    window.addEventListener("resize", handleResize);
    window.addEventListener("mousemove", handleMouseMove);

    return () => {
      cancelAnimationFrame(frameId);
      window.removeEventListener("resize", handleResize);
      window.removeEventListener("mousemove", handleMouseMove);
      if (currentMount.contains(renderer.domElement)) {
        currentMount.removeChild(renderer.domElement);
      }
      geometry.dispose();
      material.dispose();
      innerGeo.dispose();
      innerMat.dispose();
    };
  }, [colorHex, wireframe]);

  return <div ref={mountRef} className="absolute inset-0 w-full h-full z-0 pointer-events-none" />;
}

export interface AnomalousMatterHeroProps {
  title?: string;
  subtitle?: string;
  description?: string;
  badge?: string;
  colorHex?: string;
}

export function AnomalousMatterHero({
  title = "RAKSHANET • RESILIENCE MESH",
  subtitle = "Stay Connected. Save Lives Anywhere.",
  description = "An offline-first disaster communication platform that connects people, devices and rescue teams when cellular networks and power grids fail.",
  badge = "No Internet • Still Connected",
  colorHex = "#0E8A94",
}: AnomalousMatterHeroProps) {
  return (
    <section
      role="banner"
      className="relative w-full min-h-[92vh] flex flex-col justify-between bg-[#0B1220] text-[#EEF2F8] overflow-hidden"
    >
      <Suspense fallback={<div className="absolute inset-0 bg-[#0B1220]" />}>
        <GenerativeArtScene colorHex={colorHex} />
      </Suspense>

      {/* Atmospheric depth gradients */}
      <div className="absolute inset-0 bg-gradient-to-t from-[#0B1220] via-[#0B1220]/65 to-transparent z-10 pointer-events-none" />
      <div className="absolute inset-0 bg-gradient-to-r from-[#0B1220]/80 via-transparent to-[#0B1220]/80 z-10 pointer-events-none" />

      {/* Hero Content */}
      <div className="relative z-20 max-w-5xl mx-auto px-6 pt-24 pb-16 flex flex-col items-center text-center">
        {/* Network Status Badge */}
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#162036]/90 border border-[#FFD21F]/40 text-[#FFD21F] text-xs font-mono tracking-wide mb-6 shadow-lg shadow-black/40 animate-pulse">
          <Activity className="w-3.5 h-3.5 text-[#FFD21F]" />
          <span>{badge}</span>
          <span className="w-2 h-2 rounded-full bg-[#4CD08A]" />
        </div>

        <h1 className="text-xs md:text-sm font-mono tracking-widest text-[#3CC6D0] uppercase font-bold mb-3">
          {title}
        </h1>

        <p className="text-4xl md:text-6xl font-bold leading-tight tracking-tight text-[#EEF2F8] max-w-3xl">
          {subtitle}
        </p>

        <p className="mt-6 max-w-2xl text-base md:text-lg leading-relaxed text-[#9FADC2]">
          {description}
        </p>

        {/* CTA Buttons */}
        <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
          <Link
            to="/auth/login"
            className="inline-flex items-center gap-2 px-8 py-3.5 rounded-lg bg-[#FFD21F] hover:bg-[#FFC400] text-[#1A1400] font-bold text-base shadow-lg shadow-[#FFD21F]/20 transition-all transform hover:-translate-y-0.5 active:translate-y-0"
          >
            Launch Command Center
            <ArrowRight className="w-4 h-4" />
          </Link>
          <Link
            to="/app/overview"
            className="inline-flex items-center gap-2 px-8 py-3.5 rounded-lg bg-[#162036] hover:bg-[#26344F] border border-[#3A4C70] text-[#EEF2F8] font-semibold text-base transition-colors"
          >
            Live Operational Feed
          </Link>
        </div>

        {/* 4 Feature Benefit Chips from Reference Mockup */}
        <div className="mt-16 grid grid-cols-2 md:grid-cols-4 gap-4 w-full max-w-4xl">
          <div className="flex flex-col items-center p-4 rounded-xl bg-[#162036]/80 border border-[#26344F] backdrop-blur-sm text-center">
            <Radio className="w-6 h-6 text-[#FFD21F] mb-2" />
            <span className="text-sm font-bold text-[#EEF2F8]">Offline Communication</span>
            <span className="text-xs text-[#9FADC2] mt-0.5">Bluetooth Mesh Network</span>
          </div>

          <div className="flex flex-col items-center p-4 rounded-xl bg-[#162036]/80 border border-[#26344F] backdrop-blur-sm text-center">
            <MapPin className="w-6 h-6 text-[#3CC6D0] mb-2" />
            <span className="text-sm font-bold text-[#EEF2F8]">Real-time Mapping</span>
            <span className="text-xs text-[#9FADC2] mt-0.5">& Spatial Coordination</span>
          </div>

          <div className="flex flex-col items-center p-4 rounded-xl bg-[#162036]/80 border border-[#26344F] backdrop-blur-sm text-center">
            <Cpu className="w-6 h-6 text-[#4CD08A] mb-2" />
            <span className="text-sm font-bold text-[#EEF2F8]">AI-Powered Assistance</span>
            <span className="text-xs text-[#9FADC2] mt-0.5">Local Offline Triage</span>
          </div>

          <div className="flex flex-col items-center p-4 rounded-xl bg-[#162036]/80 border border-[#26344F] backdrop-blur-sm text-center">
            <ShieldAlert className="w-6 h-6 text-[#FF5A4E] mb-2" />
            <span className="text-sm font-bold text-[#EEF2F8]">Disaster Resilient</span>
            <span className="text-xs text-[#9FADC2] mt-0.5">Zero Cellular Required</span>
          </div>
        </div>
      </div>
    </section>
  );
}

export default AnomalousMatterHero;
