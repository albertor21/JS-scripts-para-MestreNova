// <GUI menuname= "Buscar por lote (v1.0)" shortcut="Ctrl+2" tooltip="Abre espectros que estan en T:\"  />

/*globals NMRSpectrum, nmr, Dir, FileDialog, File, Settings, TextStream, Application, MnUi*/
/*jslint plusplus: true, indent: 4*/

/**************************************************************
  VERSION1. 
**************************************************************/

"use strict";

const NMR_PATH = "T:\\";
const FIDS_FILENAME = "listadoFIDs.txt";
const MAX_FILES = 2;
function BuscarPorLote() {
   //dialogo para seleccionar un lote
	var setts = new Settings ("BuscarPorLote");
	dialog = new Dialog(qsTr("Abrir espectro"));
	var leEdit = new LineEdit();
	leEdit.label = qsTr("Referencia");
	leEdit.text = "";
	var leEditUserPath = new LineEdit();
	leEditUserPath.label = qsTr("Carpeta personal");
	leEditUserPath.text = setts.value( "userPath", "T:\\NMR400\\Arodriguez") ; //"T:\\NMR400\\Arodriguez";
	var leChkSave = new CheckBox();
	leChkSave.text = "Guardar por defecto";
	leChkSave.checked = true;
	var gbFolder = new GroupBox();
	//gbFolder.title = qsTr("Buscar Lote");
	gbFolder.add(leEditUserPath);
	gbFolder.add(leChkSave);
	dialog.add (leEdit);
	dialog.add(gbFolder);
	if (!dialog.exec()) {
		return;
	}
	if (txtLote == "") return;
	//guardar preferencias
	var setts = new Settings ("BuscarPorLote");
	if (leChkSave.checked){	
		setts.setValue("userPath", leEditUserPath.text);
	}
	var user_path = setts.value( "userPath", "default") ; //leEditUserPath.text.trim();
	var txtLote = leEdit.text.trim();
	
	var found = [];
	//var foundSet =  new Set(); ES6
	//######### 1ª buscar en la carpeta seleccionada en USER_PATH ############
	var arrayVacio = []
	var archivos = EnumDirs(user_path, arrayVacio);
	print (archivos.length);
	for (i=0; i  <archivos.length; i++){
		if (archivos[i].toUpperCase().indexOf(txtLote.toUpperCase()) > -1)
		//print (archivos[i]);
		found.push(archivos[i]);				
	}
	//#########y finalmente buscar en la lista de carpetas FIDS_FILENAME ubicada en NMR_PATH ###########
	var archivo = new File (	 NMR_PATH + FIDS_FILENAME)
	archivo.open(File.ReadOnly);
	var texto = new TextStream(archivo);
	while (!texto.atEnd()){
		var linea = texto.readLine();
		if (linea.toUpperCase().indexOf(txtLote.toUpperCase()) > -1){
			if (!EstaEnLista(linea, found)){ //si no esta ya en la lista found
				//print (linea);//
				found.push(linea);			
			}
		}
	}
	archivo.close();
	found.sort();
	if (found.length > MAX_FILES){
		//si se encuentran mas de MAX_FILES archivos se abre ventana de seleccion
		var dialog2 = Application.loadUiFile("ricares:BuscarPorLote.ui");
		dialog2.widgets.leList.selectionMode = 3;
		dialog2.widgets.leList.items =  found;
		dialog2.widgets.lbEdit.text =  "se han encontrado " + found.length + " coincidencias";		
		if (!dialog2.exec()) {
			return;
			}
		var selectedIndeces = dialog2.widgets.leList.selectedRows;
		var toOpen = [];
		for (var i = 0; i < selectedIndeces.length; i++){
			toOpen.push (dialog2.widgets.leList.items[selectedIndeces[i]].text);
		}	
		serialization.open(toOpen);
		return;
	}
	//else si son menos de MAX_FILES se abren todos
	serialization.open(found);
	print ("terminado");
	return;	
}
/***********************************************************
*    					EnumDirs
*  lista las carpetas terminadas en .fid a partir de path **
*  de forma recursiva
************************************************************/
function EnumDirs(path, alreadyFound) {
	var carpeta = new Dir(path);
	var resultado = [];
	resultado = alreadyFound;
	var archivos = carpeta.entryList ("*", Dir.Dirs);
	for ( var i = 0 ; i< archivos.length; i++){
		var noEsFID = !(archivos[i].indexOf(".fid")>0);
		var noEsDirActual = !(archivos[i].startsWith("."));
		if (noEsFID)  {
			if (noEsDirActual) {
				//reiterar
				EnumDirs( path + "\\" + archivos[i], resultado);
			}
		} else {
		//guardar en resultado
		resultado.push( path + "\\" + archivos[i]);
		}
	}
	return resultado;//archivos;
}

/***********************************************************
*    					EstaEnLista
* 		 true si texto esta en el array lista **
************************************************************/
function EstaEnLista(texto, lista) {
	for ( var i = 0 ; i< lista.length; i++){
		if (lista[i].toUpperCase().indexOf(texto.toUpperCase()) > -1){
			return true;
		}
	}
	return false;
}
