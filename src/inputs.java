import java.util.ArrayList;
import java.util.List;

public class inputs {
    public static void main(String[] args) {

        System.out.println(permute(new int[] {1,2,3}));

    }
    public static List<List<Integer>> permute(int[] nums) {

        List<List<Integer>> list = new ArrayList<>();
        List<Integer> temparray = new ArrayList<>();
        boolean[] used = new boolean[nums.length];
        recurse(list,temparray,used,nums);
        return list;


    }





    public static void recurse(List<List<Integer>> list, List<Integer> temparray, boolean[] used, int[] nums){
        if(nums.length == temparray.size()){
            list.add(new ArrayList<>(temparray));
        }

        for(int i=0; i < nums.length; i++){
            if(!used[i]){
                used[i] = true;
                temparray.add(nums[i]);
                recurse(list,temparray,used,nums);
                temparray.remove(temparray.size()-1);
                used[i] = false;
            }
        }

    }

}
