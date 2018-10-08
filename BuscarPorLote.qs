// <GUI menuname= "Buscar por lote (v1.2)" shortcut="Ctrl+2" tooltip="Abre espectros que estan en T:\"  />

/*globals NMRSpectrum, nmr, Dir, FileDialog, File, Settings, TextStream, Application, MnUi*/
/*jslint plusplus: true, indent: 4*/

/**************************************************************
  VERSION1.2
  añadido soporte para abrir archivos mnova de la carpeta de 
  espectros si el lote introducido empieza por PM,Mi, CD o IB
**************************************************************/

"use strict";

const NMR_PATH = "T:\\";
const MNOVA_FILES_PATH = "H:\\ID - Investigacion y Desarrollo\\3_MEDICINAL_CHEMISTRY\\2_NATURAL_PRODUCTS_CHEMISTRY\\BBDD RMN\\";
const FIDS_FILENAME = "listadoFIDs.txt";
const MAX_FILES = 2;
function BuscarPorLote() {
   //dialogo para seleccionar un lote
	var setts = new Settings ("BuscarPorLote");
	dialog = new Dialog(qsTr("Abrir espectro"));
	var leEdit = new LineEdit();
	leEdit.label = qsTr("Referencia");
	leEdit.text = setts.value( "lastBatch", "") ;
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
	leEdit.setFocus(true); //tiene que ir aqui
	if (!dialog.exec()) {
		return;
	}
	
	//guardar preferencias
	var setts = new Settings ("BuscarPorLote");
	if (leChkSave.checked){	
		setts.setValue("userPath", leEditUserPath.text);
	}
	setts.setValue("lastBatch", leEdit.text);
	var user_path = setts.value( "userPath", "default") ; //leEditUserPath.text.trim();
	var txtLote = leEdit.text.trim();

	if (txtLote == "") return;
	var prefix = txtLote.substr(0,2);
	//Si es PM o MI o CD... se abre el archivo *.mnova de la carpeta de espectros
	if (prefix == "PM" || prefix == "CD" || prefix == "MI" || prefix == "IB"){
		var path_completo = MNOVA_FILES_PATH +  txtLote + "\\" +  txtLote + ".mnova" ;
		print (path_completo);
		serialization.open(path_completo);
		return;
	}
	
	
	var found = [];
	//var foundSet =  new Set(); ES6
	//######### 1ª buscar en la carpeta seleccionada en USER_PATH ############
	var arrayVacio = []
	var archivos = EnumDirs(user_path, arrayVacio);
	print (archivos.length + " archivos");
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
		ShowDialog(found);
		return;
	}
	//else si son menos de MAX_FILES se abren todos
	serialization.open(found);
	print ("terminado");
	return;	
}

/***********************************************************
*    					ShowDialog
*  muestra un cuadro de dialogo para mostrar todos los    **
*  espectros encontrados y seleccionar los que se quieran
************************************************************/
function ShowDialog(found) {
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
