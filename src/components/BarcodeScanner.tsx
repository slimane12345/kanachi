import React, { useEffect, useRef, useState } from 'react';
import { Html5QrcodeScanner, Html5QrcodeSupportedFormats } from 'html5-qrcode';
import { Camera, X, Zap, ZapOff } from 'lucide-react';

interface BarcodeScannerProps {
    onScan: (barcode: string) => void;
    onClose: () => void;
}

export default function BarcodeScanner({ onScan, onClose }: BarcodeScannerProps) {
    const scannerRef = useRef<Html5QrcodeScanner | null>(null);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        // Initialise scanner
        const scanner = new Html5QrcodeScanner(
            "barcode-reader",
            {
                fps: 10,
                qrbox: { width: 250, height: 150 },
                aspectRatio: 1.777778, // 16:9
                showTorchButtonIfSupported: true,
                formatsToSupport: [
                    Html5QrcodeSupportedFormats.EAN_13,
                    Html5QrcodeSupportedFormats.EAN_8,
                    Html5QrcodeSupportedFormats.CODE_128,
                    Html5QrcodeSupportedFormats.QR_CODE,
                    Html5QrcodeSupportedFormats.UPC_A,
                    Html5QrcodeSupportedFormats.UPC_E,
                ]
            },
      /* verbose= */ false
        );

        scanner.render(
            (decodedText) => {
                // Play sound feedback
                try {
                    const audio = new Audio('https://assets.mixkit.co/active_storage/sfx/2571/2571-preview.mp3');
                    audio.play();
                } catch (e) {
                    console.error('Audio play failed', e);
                }

                // Vibrate if supported
                if (navigator.vibrate) {
                    navigator.vibrate(100);
                }

                onScan(decodedText);
            },
            (errorMessage) => {
                // Silently ignore intermittent scan errors
            }
        );

        scannerRef.current = scanner;

        return () => {
            if (scannerRef.current) {
                scannerRef.current.clear().catch(err => {
                    console.error("Failed to clear scanner", err);
                });
            }
        };
    }, [onScan]);

    return (
        <div className="fixed inset-0 bg-black z-[200] flex flex-col items-center justify-center p-4">
            <div className="absolute top-6 left-6 right-6 flex justify-between items-center z-10">
                <div className="bg-emerald-600/80 backdrop-blur-md px-4 py-2 rounded-2xl flex items-center gap-2 text-white border border-white/20">
                    <Camera className="w-5 h-5" />
                    <span className="font-black text-sm uppercase tracking-wider">جارٍ المسح...</span>
                </div>
                <button
                    onClick={onClose}
                    className="bg-white/10 hover:bg-white/20 backdrop-blur-md p-3 rounded-2xl text-white border border-white/20 transition-all active:scale-90"
                >
                    <X className="w-6 h-6" />
                </button>
            </div>

            <div className="w-full max-w-lg aspect-[3/4] bg-slate-900 rounded-[40px] overflow-hidden relative shadow-2xl border-2 border-white/10">
                <div id="barcode-reader" className="w-full h-full"></div>

                {/* Interactive Overlay */}
                <div className="absolute inset-0 pointer-events-none flex flex-col items-center justify-center">
                    <div className="w-64 h-40 border-2 border-emerald-500 rounded-3xl relative overflow-hidden shadow-[0_0_50px_rgba(16,185,129,0.3)]">
                        <div className="absolute inset-x-0 h-0.5 bg-emerald-500 shadow-[0_0_15px_rgba(16,185,129,1)] animate-scan-line"></div>
                    </div>
                    <p className="mt-8 text-white/50 text-xs font-bold uppercase tracking-[0.2em] animate-pulse">
                        ضع الباركود داخل الإطار
                    </p>
                </div>
            </div>

            <div className="mt-8 text-center text-white/40 text-[10px] font-medium max-w-xs leading-relaxed uppercase tracking-widest px-8">
                تأكد من وجود إضاءة كافية للحصول على نتائج أفضل
            </div>

            <style>{`
        @keyframes scan-line {
          0% { top: 0; }
          100% { top: 100%; }
        }
        .animate-scan-line {
          animation: scan-line 2s linear infinite;
        }
        #barcode-reader__dashboard {
          background-color: transparent !important;
          border: none !important;
          padding: 20px !important;
        }
        #barcode-reader__camera_selection {
          background-color: rgba(255,255,255,0.1) !important;
          color: white !important;
          border-radius: 12px !important;
          padding: 8px !important;
          border: 1px solid rgba(255,255,255,0.2) !important;
          width: 100% !important;
          margin-top: 10px !important;
        }
        #barcode-reader__dashboard_section_csr button {
          background-color: #10b981 !important;
          color: white !important;
          border-radius: 12px !important;
          padding: 10px 20px !important;
          font-weight: bold !important;
          border: none !important;
          margin-top: 10px !important;
          text-transform: uppercase !important;
          letter-spacing: 1px !important;
          font-size: 12px !important;
        }
      `}</style>
        </div>
    );
}
