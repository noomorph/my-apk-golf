package b.c;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;

public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

//        System.loadLibrary("wed1");
//        System.loadLibrary("wed2");

        TextView textView = new TextView(this);
        textView.setText(getSomeString());
        setContentView(textView);
    }

    private native String getSomeString();
}
