// Assemble les captures en une planche (docs/captures/planche.png)
const fs=require('fs'),path=require('path'),{PNG}=require('pngjs');
const dir=path.join(__dirname,'..','docs','captures');
const files=fs.readdirSync(dir).filter(f=>/^\d\d_.*\.png$/.test(f)).sort();
const cols=4, rows=Math.ceil(files.length/cols), W=256, H=240, G=4;
const out=new PNG({width:cols*(W+G)+G,height:rows*(H+G)+G});
out.data.fill(40);
files.forEach((f,i)=>{const img=PNG.sync.read(fs.readFileSync(path.join(dir,f)));const ox=G+(i%cols)*(W+G),oy=G+Math.floor(i/cols)*(H+G);
for(let y=0;y<H;y++)for(let x=0;x<W;x++){const s=(y*W+x)*4,d=((oy+y)*out.width+ox+x)*4;for(let k=0;k<4;k++)out.data[d+k]=img.data[s+k];}});
fs.writeFileSync(path.join(dir,'planche.png'),PNG.sync.write(out));
