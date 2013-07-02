#javac -cp ./:gui-model-jfc.jar:gui-model-core.jar:guistructure2graph-efg.jar:guistructure2graph-core.jar JFCXListener.java
rm -rf *.class
javac -cp ./:gui-model-jfc.jar:gui-model-core.jar:guistructure2graph-efg.jar:guistructure2graph-core.jar CaptureReplay.java
java -cp ./:gui-model-jfc.jar:gui-model-core.jar:guistructure2graph-efg.jar:guistructure2graph-core.jar CaptureReplay
