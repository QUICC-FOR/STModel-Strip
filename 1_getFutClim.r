# open the db connection
source('./con_quicc_db.r')

# load libs
library("RPostgreSQL")

# read list of GCMs
GCM_df <- read.csv("./data/list_GCMs.csv")
GCM_df <- subset(GCM_df, scenario == 'rcp85')

windows <- seq(2000,2095,5)
out_folder <- "./data/futClimSTM/"

for (x in 1:dim(GCM_df)[1]){
    system(paste("mkdir -p ",out_folder,"GCM_id_",rownames(GCM_df)[x],sep=""))

    for (i in 1:length(windows)){

    query_fut_climData <- paste("SELECT ST_X(geom) as lon, ST_Y(geom) as lat, x , y, var, ", windows[i]-15 ," as min_yr,",windows[i]," as max_yr, val, clim_center, mod, run, scenario FROM (
    SELECT var,clim_center, mod, run, scenario, (ST_PixelAsCentroids(ST_Union(ST_Clip(ST_Transform(raster,32198),1,env_plots,true),'MEAN'),1,false)).*
    FROM clim_rs.fut_clim_biovars,
    (SELECT ST_GeomFromText('POLYGON((-475408.2 194979.3,-475408.2 717179.3,-389008.2 717179.3,-389008.2 194979.3,-475408.2 194979.3))',32198) as env_plots) as envelope
    WHERE (var='bio1' OR var='bio12') AND (yr>=",windows[i]-15," AND yr<=",windows[i],") AND clim_center='",GCM_df[x,1],"' AND mod='",GCM_df[x,2],"' AND run='",GCM_df[x,3],"' AND scenario='",GCM_df[x,4],"' AND ST_Intersects(ST_Transform(raster,32198),env_plots)
    GROUP BY var,clim_center, mod, run, scenario
    ) as pixels;",sep="")

    cat("Querying id: ",rownames(GCM_df)[x],"; processing window:", windows[i]-15, "-", windows[i], "\n")

    fut_climData <- dbGetQuery(con, query_fut_climData)

    write.table(fut_climData, file=paste(out_folder,"GCM_id_",rownames(GCM_df)[x],"/GCM_id_",rownames(GCM_df)[x],"_win_",windows[i]-15,"-",windows[i],".csv",sep=""), sep=',', row.names=FALSE)

    }
}
