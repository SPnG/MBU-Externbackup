#!/bin/bash


# Sichert /home/david sowie /etc und auf RDX
# 
# Als root ausfuehren!
#
# SPnG (MBU,FW), Stand: Juni 2013


# zum Anpassen ################################################################

LOG=/tmp/dvbackup.log
MAIL=david@localhost
#
TAPE=/dev/sdd            # VORSICHT, es erfolgt keine Pruefung!

# #############################################################################









# Abfahrt



# Pruefung auf Rootrechte:
if [ ! "`id -u`" -eq "0" ]; then
   echo "ABBRUCH, keine Rootrechte :-(" | tee -a $LOG
   echo ""
   exit 1
fi

JETZT=`date +%c` && echo $JETZT >>$LOG
echo ""
echo ""
echo "DV Datensicherung (ohne Dokumentenablage!)" | tee -a $LOG
echo "------------------------------------------"

if [ -e $LOG ]; then
   rm -f $LOG
fi

echo ""
echo "Bitte Medium einlegen und ENTER druecken... (Abbruch mit STRG-C)"
read dummy

# ISAM anhalten
JETZT=`date +%c` && echo $JETZT >>$LOG
echo "ISAM Dienst wird beendet..." | tee -a $LOG
cd /home/david
./iquit
if [ `ps ax | grep isam | wc -l` -lt 3 ]; then
   echo "ISAM beendet." | tee -a $LOG
else
   echo "Fehler beim Beenden des ISAM Dienstes." | tee -a $LOG
fi

# Sicherung
cd /home/david
echo "Datensicherung laeuft..." | tee -a $LOG
#
tar -cv --one-file-system --exclude=Trash                \
                          --exclude=*_uds*               \
                          --exclude=/var/lib/imap/socket \
                          --exclude=trpword/pat_nr       \
        -f $TAPE /home/david /etc >>$LOG 2>&1
#
WERT=`echo $?`
if [ $WERT == 0 ]; then
   echo "RDX-Sicherung erfolgreich." | tee -a $LOG
else
   echo "Fehler bei der RDX-Sicherung." | tee -a $LOG
fi

echo "ISAM Dienst wird gestartet..." | tee -a $LOG
cd /home/david
./isam
if [ `echo $?` == 0 ]; then
   echo "ISAM Dienst laeuft." | tee -a $LOG
else
   echo "Fehler beim ISAM Start." | tee -a $LOG
fi

echo "RDX-Auswurf..." | tee -a $LOG
eject $TAPE
if [ `echo $?` == 0 ]; then
   echo "Bandauswurf erfolgreich." | tee -a $LOG
else
   echo "Fehler beim Bandauswurf." | tee -a $LOG
fi

# Logdatei abschliessen und senden
echo "-------------------------------"
echo "Backup beendet." | tee -a $LOG
JETZT=`date +%c` && echo $JETZT >>$LOG
cat $LOG | mail -s "Bericht zur Bandsicherung" $MAIL

echo ""
exit 0
