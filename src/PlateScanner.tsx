import {useRef,useState} from 'react';
import {createWorker} from 'tesseract.js';

const platePattern = /[A-Z]{3}[0-9][A-Z0-9][0-9]{2}/g;
function extractPlate(text:string):string|null{
 const cleaned=text.toUpperCase().replace(/[^A-Z0-9]/g,'');
 const candidates=cleaned.match(platePattern)||[];
 return candidates.find(p=>/^[A-Z]{3}[0-9](?:[0-9]{3}|[A-Z][0-9]{2})$/.test(p))||null;
}
type Props={onRead:(plate:string)=>void};
export function PlateScanner({onRead}:Props){
 const video=useRef<HTMLVideoElement>(null);
 const stream=useRef<MediaStream|null>(null);
 const [open,setOpen]=useState(false);
 const [busy,setBusy]=useState(false);
 const [message,setMessage]=useState('');
 const [preview,setPreview]=useState('');
 const stop=()=>{stream.current?.getTracks().forEach(t=>t.stop());stream.current=null;setOpen(false)};
 async function start(){
  setMessage('');
  if(!navigator.mediaDevices?.getUserMedia){setMessage('Câmera indisponível. Abra o site em HTTPS e permita o acesso à câmera.');return}
  try{
   const s=await navigator.mediaDevices.getUserMedia({video:{facingMode:{ideal:'environment'},width:{ideal:1280},height:{ideal:720}},audio:false});
   stream.current=s;setOpen(true);
   requestAnimationFrame(()=>{if(video.current){video.current.srcObject=s;void video.current.play().catch(()=>{})}});
  }catch{setMessage('Não foi possível acessar a câmera. Verifique a permissão do navegador.')}
 }
 async function recognize(source:HTMLCanvasElement){
  setBusy(true);setMessage('Reconhecendo placa…');
  let worker:Awaited<ReturnType<typeof createWorker>>|undefined;
  try{
   worker=await createWorker('eng');
   await worker.setParameters({tessedit_char_whitelist:'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',preserve_interword_spaces:'0'});
   const result=await worker.recognize(source);
   const found=extractPlate(result.data.text);
   if(found){setPreview(found);setMessage('Confira a placa identificada antes de confirmar.');stop()}
   else setMessage('Não foi possível identificar uma placa. Aproxime a câmera, evite reflexos e tente novamente.');
  }catch{setMessage('Falha no reconhecimento. Verifique a conexão e tente novamente ou digite a placa.')}
  finally{if(worker)await worker.terminate().catch(()=>{});setBusy(false)}
 }
 async function capture(){
  const v=video.current;if(!v||!v.videoWidth)return;
  const canvas=document.createElement('canvas');
  canvas.width=v.videoWidth;canvas.height=v.videoHeight;
  const ctx=canvas.getContext('2d');if(!ctx)return;
  ctx.drawImage(v,0,0);
  await recognize(canvas);
 }
 async function upload(e:React.ChangeEvent<HTMLInputElement>){
  const file=e.target.files?.[0];if(!file)return;
  try{
   const bitmap=await createImageBitmap(file);
   const canvas=document.createElement('canvas');canvas.width=bitmap.width;canvas.height=bitmap.height;
   canvas.getContext('2d')?.drawImage(bitmap,0,0);bitmap.close();
   await recognize(canvas);
  }catch{setMessage('Não foi possível abrir a imagem.')}
  finally{e.target.value=''}
 }
 return <section className="scanner" aria-label="Leitor de placas">
  <div className="scanner-actions">
   <button type="button" className="scan-button" onClick={()=>open?stop():void start()} disabled={busy}>{open?'Fechar câmera':'📷 Ler placa pela câmera'}</button>
   <label className="file-button">Usar foto<input type="file" accept="image/*" capture="environment" onChange={e=>void upload(e)} disabled={busy}/></label>
  </div>
  {open&&<div className="camera-panel"><video ref={video} autoPlay playsInline muted aria-label="Visualização da câmera"/><div className="plate-guide" aria-hidden="true"/><button type="button" disabled={busy} onClick={()=>void capture()}>Capturar e reconhecer</button></div>}
  {busy&&<p role="status">Processando imagem no dispositivo. Aguarde…</p>}
  {message&&<p role="status" className="scan-message">{message}</p>}
  {preview&&<div className="plate-confirm"><label htmlFor="detected-plate">Placa identificada</label><input id="detected-plate" maxLength={7} value={preview} onChange={e=>setPreview(e.target.value.toUpperCase().replace(/[^A-Z0-9]/g,''))}/><button type="button" disabled={!/^[A-Z]{3}[0-9](?:[0-9]{3}|[A-Z][0-9]{2})$/.test(preview)} onClick={()=>{onRead(preview);setPreview('');setMessage('Placa preenchida. Confira os dados do veículo.')}}>Confirmar placa</button></div>}
 </section>
}
