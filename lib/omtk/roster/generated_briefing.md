>>>Articulation des Forces<<<

// BLUEFOR weapons
{% for class in bluefor %}
# Platoon BLUEFOR
|                           | Platoon Leader  | Rifle Squad #1 | Rifle Squad #2 | Rifle Squad #3    | Blindés    |
|:--------------------------|:----------------|:---------------|:---------------|:------------------|:-----------|
| Chef de Camp              |                 | -              | -              | -                 | -          |
| *EFFECTIF*                | 1/1             | 5/7            | 5/7            | 6/7               | 1/1        |
{% endfor %}

// REDFOR weapons
{% for class in redfor %}
# Platoon REDFOR
|                           | Platoon Leader  | Rifle Squad #1 | Rifle Squad #2 | Rifle Squad #3    | Blindés    |
|:--------------------------|:----------------|:---------------|:---------------|:------------------|:-----------|
| Chef de Camp              |                 | -              | -              | -                 | -          |
| *EFFECTIF*                | 1/1             | 5/7            | 5/7            | 6/7               | 1/1        |

{% endfor %}


**** : slot non-occupé

>>>Orientation<<<

#Théâtre Opérationnel

*inserer une carte et les explications des zones*

#Météo & Conditions

Heure de début de mission: {{ mission_start_time }} loc.  
Heure de fin de mission: {{ mission_end_time }} loc.

{{ mission_current_weather }}
{{ mission_weather_forecast }}

>>>Situation Ennemie<<<
#Force

*inconnue ?*

#Armement

*inconnu ?*

#Dispositif

*inconnu ?*

#Attitude

*inconnue ?*

>>>Situation Alliée<<<

# Objectifs

*Description des objectifs*

# Ordres de Batailles


>>>Administration Logistique<<<

*Topo sur les ressources engagees ou non, gestion de la campagne*

>>>Mission<<<

#Par Groupe


#Exécution


>>>Liaison & Commandement<<<

# Plan de fréquences

|                                | Rifle Squad #1: | Rifle Squad #2 | Rifle Squad #3  
|:-------------------------------|:---------------:|:---------------:|:--------------
| Indicatif                      |                 |                 |            
| Canal Courte-Portée primaire   |                 |                 |            
| Canal Courte-Portée de garde   |                 |                 |               
| Canal Longue-Portée principal  |                 |                 |               
| Canal Longue-Portée additionel |                 |                 |            

# Nom de codes


# Chaine de Commandement

##Position du CdC

##Relève du CdC


