 
 var
        
    dx = [],a01=[], a02=[], a03 = [],a04=[],
    a05 = [],a06 = [],a07=[],a08 = [], a09 = [],
    a10 = [],a11 = [];
 

 
 
 function doFlot ()
{ 
    var f,i,j;
	 
			if(prez==1)
			{
						for (j = 0; j < y; j += 1)
						{
							f = new Date(2000,12,31);
							f=Date.parse(Surs0[j]);
							dx .push(f);
							}
							t=y;
			}
			
			if(prez==2) {dx=Surs0; t=8;}
			
     
   for (i = 0; i < t; i += 1)
        {
          
       if(bool_list[1])  a01.push([dx [i], Surs1[i]]);
       if(bool_list[2])  a02.push([dx [i], Surs2[i]]);           
       if(bool_list[3])  a03.push([dx [i], Surs3[i]]);
       if(bool_list[4])  a04.push([dx [i], Surs4[i]]);           
       if(bool_list[5])  a05.push([dx [i], Surs5[i]]);			
		 if(bool_list[6])	 a06.push([dx [i], Surs6[i]]);
		 if(bool_list[7])	 a07.push([dx [i], Surs7[i]]);
		 if(bool_list[8])	 a08.push([dx [i], Surs8[i]]);
		 if(bool_list[9])	 a09.push([dx [i], Surs9[i]]);			
       if(bool_list[10]) a10.push([dx [i], Surs10[i]]);
       if(bool_list[11]) a11.push([dx [i], Surs11[i]]);         
    
         
        } 
    
         var r1,r2,r3;  
     if(prez==1) {r1=null; r2="time"; r3=0570000022408;}  
     
    if(prez==2) { r1=[[0,"н/к"],[1,"1 кс"],[2,"2 кс"],[3,"3 кс"],
				[4,"4 кс"],[5,"5 кс"],[6,"6 кс"],[7,"пут."]],
					  r2=null, r3=0}
				

     var chartConfig = { 

       xaxis: {
			 
		ticks:r1,
				
				mode:r2 ,  min: r3
			 
		},

       legend: {show: true, 
                 container : $('#legend')
		           },

       yaxis: {min:0},

       x2axis:  {   },

       y2axis: {},

        points: {show: true,//show: true узловые точкш
                 radius:4,    //радиус кружка  
					  fill: true, //заполнить кружок
					  //fillColor: "grid",
					  //цвег заполнения
					  
                },
					 

       lines: {show:true , lineWidth: 4, fill: false, fillColor: '#ca0000' },

        bars: {
                   show: false,
                    horizontal: false, // столбцы горизонтально
                    shadowSize: 0,     // тени размер
                    barWidth: 0.5      //ширина столбца
                },

       grid: 
       
{ clickable: true,
   hoverable: true,
   autoHighlight: true, 
   mouseActiveRadius: 15 
		},

       selection: {},

       shadowSize: 5,//тени

       colors: [
       '#DC143C',   //все
       '#228B22', //пеший 
       '#AFEEEE', //лыжный
       '#F4A460', // горный
       '#1E90FF', //водный        
       '#696969', //вело
		 '#151B54', //Авто
		 '#3EA99F',//Спелео
		 '#E0FFFF',//Парус
		 '#7E3517',//Конный
       '#9400D3' //комби       
       
       ]   //цвета графиков

     };

     

    // и строим саму диагрумму
    
    

     

   $.plot($("#placeholder"), 

     [ 
          { data:a11, label: "Все"
             ,lines: {show: true, lineWidth:8 , fill:  true, fillColor:'rgba(107,142,35,0.3)', }
          },
          { data:a01,    label:"Пеший"  },
          { data:a02,    label: "Лыжный"},
          { data:a03,    label: "Горный"},			 
          { data:a04,    label: "Водный"},
          { data:a05,    label: "Вело"  },
			 { data:a06,    label: "Авто"  },
			 { data:a07,    label: "Спелео"},
			 { data:a08,    label: "Парус" },
			 { data:a09,    label: "Конный"},			 
          { data:a10,    label: "Комби" }
         

     ], 

        chartConfig);
 }
 
 
     function showTooltip(x, y, contents) {
      $('<div id="tooltip">' + contents + '</div>').css( {
         position: 'absolute',
         display: 'none',
         top: y + 5, left: x + 5,
         border: 'solid 2px #598d23',
			"border-radius":'5px', 
         padding: '2px',
			
         'background-color': '#fee',
         opacity: 0.80
      }).appendTo("body").fadeIn(200);

    }
    
    
        $("#placeholder").bind("plothover", 
      function (event, pos, item) {
         $("#tooltip").remove();
         if (! item) return;     
         var k_s=["н/к","1 кс","2 кс","3 кс","4 кс","5 кс","6 кс","пут."]
         var x = item.datapoint[0].toFixed(2);
         var y = item.datapoint[1].toFixed(2);
			var dates = new Date(Number(x));
			if(prez==1)
         var label = item.series.label+"<br/>"+  Math.floor(y) + " чел.<br/> "+ dates.getFullYear()+ " г.";
			if(prez==2)
			var label = item.series.label+"<br/>"+  Math.floor(y) + " чел. <br/>"+	k_s[Number(x)];
			
         showTooltip(item.pageX, item.pageY,  label);

      }

    );
 
 
 
 $(document).ready(doFlot);