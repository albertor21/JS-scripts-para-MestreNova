// <GUI menuname= "saveNMRsToEasyReg (v2.0)" shortcut="Ctrl+1" tooltip="Guarda los espectros en formato Nova y pdf para ser vistos en chemreg"  />

/*globals NMRSpectrum, nmr, settings, Dir, FileDialog, File, TextStream, Application, MnUi*/
/*jslint plusplus: true, indent: 4*/

/**************************************************************
  VERSION 2. Guarda el espectro como pdf, mNova y genera los
  archivos txt de picos y el archivo del espectro completo.
  para espectros de 1H y 13C
**************************************************************/



"use strict";

const NMR_PATH = "H:\\ID - Investigacion y Desarrollo\\3_MEDICINAL_CHEMISTRY\\2_NATURAL_PRODUCTS_CHEMISTRY\\BBDD RMN\\";
	const PROCESSING_PATH = "H:\\ID - Investigacion y Desarrollo\\3_MEDICINAL_CHEMISTRY\\2_NATURAL_PRODUCTS_CHEMISTRY\\BBDD RMN\\";


function saveNMRsToEasyReg() {
	
	var leDirectory;
   // var dirName = settings.value(NMR_PATH, Dir.home());
   //dialogo para seleccionar PM
	dialog = new Dialog(qsTr("Guardar para EasyReg"));
	leDirectory = new LineEdit();
	leDirectory.label = qsTr("Código PM:");
	leDirectory.text = "PM";
	gbFolder = new GroupBox();
	gbFolder.title = qsTr("Seleccionar PM");
	gbFolder.add(leDirectory);
	dialog.add(gbFolder);
	if (!dialog.exec()) {
		return;
	}
	PMtext = leDirectory.text;
	var pathCompleto = NMR_PATH + PMtext + "\\";
	//si no existe la carpeta, se crea
	carpeta = new Dir(pathCompleto);
	if (!carpeta.exists){
		carpeta.mkdir (pathCompleto);
		print("se creo la carpeta" + pathCompleto + " porque no existia");
	}
	/*************************************/
	savePDFyMnova(pathCompleto, PMtext);
	/*************************************/
	var spec = new NMRSpectrum( nmr.activeSpectrum() );	
	var dW = new DocumentWindow(Application.mainWindow.activeWindow());

	for(var i = 0; i < dW.pageCount(); i++){
		var pag = new Page(dW.page(i));
		print ( "Page number "+i+" has "+pag.itemCount()+" items" );
		for( var j = 0; j < pag.itemCount(); j++ ){
			var item = new PageItem(pag.item(j));
			print( "\t"+item.name );
			var spectrum = new NMRSpectrum(item);
			if(spectrum.isValid()){	
				var spec = new NMRSpectrum(item);		
				var processing = new String;

				if (spec.dimCount == 1){

					if (spec.nucleus() == "1H"){
		processing = PROCESSING_PATH + "HNMR.mnp";
					}else {
					processing =  PROCESSING_PATH + "CNMR.mnp" ;;
					}		
					var filename
					nmr.processSpectrum(spec, processing);	
					/***********************************************************/
					filename = pathCompleto + PMtext; //
					savePicos (filename, spec);
					/*************************************************/
					filename = pathCompleto + PMtext;		
					saveRMNCompleto (filename, spec);
					/*****************************************************/	
				} //dimcount	
			} //isValid	
		} //for
	} //for
	//dW.close();
	//Application.quit();
}


function savePDFyMnova(path, Pm) {
	var path_completo_mnova = path + Pm + ".mnova"
	var path_completo_pdf = path + Pm + "_rmn.pdf"
	var archivo = new Dir(path + Pm);
	if (archivo.fileExists(path_completo_mnova)){
		//si existia el archivo se borra y se guarda de nuevo
		print("Ya existia el archivo " + path_completo_mnova);
		var fileToDelete = File (path_completo_mnova);
		print(fileToDelete.remove());

	}
	print ("guardando "  +  path_completo_pdf)
	serialization.save( path_completo_pdf, "pdf");	
	print ("guardando "  + path_completo_mnova)
	serialization.save(path_completo_mnova);		
	return;
}

function savePicos(filename, spec){
	print("Saving " + filename);	
	var nuc = spec.getParam("Nucleus");
	var freq = spec.getParam("Spectrometer Frequency");
	var solvent = spec.getParam("Solvent");	
	filename = filename + nuc + solvent + "picos.txt";
	fout = new File(filename);
	fout.open(File.WriteOnly);
	sout = new TextStream(fout);
	sout.precision = 3;
	freq = spec.frequency(1);
	points = spec.count(1);
	sw = spec.scaleWidth(1);
	sout.write(nuc,"\n");
	sout.write(freq,"\n");
	sout.write(solvent,"\n");
	var peaks = spec.peaks();
	var picosCompuestoPpm = [];
	var picosCompuestoInt = [];
	var maxIntensity = -1;//Infinity;
	var n = peaks.count;
	for (k = 0; k < n; k++) {
		var peak = peaks.at(k);
		if (peak.type == 0) { // si es pico de compuesto
			picosCompuestoPpm.push (peak.delta().toFixed(2));
			picosCompuestoInt.push (peak.intensity.toFixed(1));
		}					
	} //enf for
	for (k = 0; k < picosCompuestoPpm.length; k++) {
		var ppm = picosCompuestoPpm[k];
		if ((ppm > 1.5) && (ppm < 3.20 || ppm > 3.39) && (ppm < 4.70 || ppm > 4.89)) { 
		// si es pico de compuesto pero no disolventes o mayor que grasas
			if (Number(picosCompuestoInt[k])> maxIntensity) { // calcular la intensidad maxima
				maxIntensity = picosCompuestoInt[k];
				var ppmMaximaInt = ppm;
				//print ("MaxHastaAhora: " + ppm + " , " + maxIntensity);
			}
		}
	} //enf for
	/*buscar maximo*/
	var picosCompuestoPpmNorm = [];
	var picosCompuestoIntNorm = [];
	var LIMITE =  maxIntensity*0.02; //EL 0.5%
	for (k = 0; k < picosCompuestoPpm.length; k++) {
		if (picosCompuestoInt[k] > LIMITE){
			picosCompuestoPpmNorm.push (picosCompuestoPpm[k]);
			picosCompuestoIntNorm.push (picosCompuestoInt[k]);
		}				
	}
	//escribo el archivo sin meter duplicado
	//el primer dato
	sout.write(picosCompuestoPpmNorm[0]);
	//ahora el resto de datos desde 1 hasta n
	for (k = 1; k < picosCompuestoPpmNorm.length; k++) {
		//si el dato es igual a anterior no se escribe
		if (picosCompuestoPpmNorm[k] !=  picosCompuestoPpmNorm[k-1] ){
			sout.write(",", picosCompuestoPpmNorm[k]);
		}
	}
	fout.close();
	return;
}

function saveRMNCompleto(filename, spec){
	var nuc = spec.getParam("Nucleus");
	var freq = spec.getParam("Spectrometer Frequency");
	var solvent = spec.getParam("Solvent");
	filename = filename + nuc + solvent + ".txt"	
	var fout = new File(filename);
	var sout = new TextStream(fout);	
	
	sout.precision = 4;
	fout.open(File.WriteOnly);
	sout.write(nuc, "\n");
	sout.write(freq, "\n");
	sout.write(solvent, "\n");
	var lastOutName = NMR_PATH + "temp.txt";
	var flastOut = new File(lastOutName);
	var slastOut = new TextStream(flastOut);

	// Put first column of the file in ppm. The scale is taken from the first spectrum.
	flastOut.open(File.WriteOnly);
	slastOut.precision = 4;
	var ppm = spec.hz(1)/spec.frequency(1);
	var dPpm = spec.scaleWidth(1)/spec.count(1)/spec.frequency(1);
	for(var si = spec.count(1)-1; si >= 0; si--)
		{
			slastOut.write(ppm, "\n");
			ppm += dPpm;
		}
			flastOut.close();
			flastOut.open(File.ReadOnly);
		// Put intensities in the second column of the file.
	for(var si = spec.count(1)-1; si >= 0; si--)
	{
		sout.write(slastOut.readLine(), "\t", spec.real(si), "\n");
	}

	fout.close();
	flastOut.close();
	flastOut.remove();
	return;
}
